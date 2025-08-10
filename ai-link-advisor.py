#!/usr/bin/env python3
"""
Cortex AI Link Advisor
Intelligent link suggestions and broken link repair using AI analysis
"""

import os
import re
import json
import sqlite3
from pathlib import Path
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass
from datetime import datetime
import argparse
import subprocess

@dataclass
class LinkSuggestion:
    """Represents an AI-generated link suggestion"""
    broken_link: str
    suggested_target: str
    confidence: float
    reasoning: str
    context: str
    file_path: str
    line_number: int

@dataclass
class LinkPattern:
    """Represents a learned link pattern"""
    pattern: str
    target_template: str
    usage_count: int
    success_rate: float

class AILinkAdvisor:
    """Main AI Link Advisor class"""
    
    def __init__(self, cortex_path: str, framework_path: str):
        self.cortex_path = Path(cortex_path)
        self.framework_path = Path(framework_path)
        self.db_path = self.framework_path / "ai_link_advisor.db"
        self.patterns_cache = {}
        self._init_database()
    
    def _init_database(self):
        """Initialize SQLite database for learning and caching"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Create tables for learning
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS link_patterns (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                pattern TEXT UNIQUE NOT NULL,
                target_template TEXT NOT NULL,
                usage_count INTEGER DEFAULT 1,
                success_count INTEGER DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS broken_link_history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                broken_link TEXT NOT NULL,
                suggested_fix TEXT,
                was_accepted BOOLEAN,
                file_path TEXT,
                context TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS content_similarity (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                file_a TEXT NOT NULL,
                file_b TEXT NOT NULL,
                similarity_score REAL NOT NULL,
                common_concepts TEXT,
                calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        conn.commit()
        conn.close()
    
    def analyze_existing_links(self) -> Dict[str, List[str]]:
        """Analyze existing valid links to learn patterns"""
        print("🔍 Analyzing existing link patterns...")
        
        link_map = {}
        concept_map = {}
        
        for md_file in self.cortex_path.rglob("*.md"):
            try:
                content = md_file.read_text(encoding='utf-8')
                
                # Extract concepts from filename and content
                concepts = self._extract_concepts(md_file, content)
                concept_map[str(md_file)] = concepts
                
                # Find all links in the file
                wiki_links = re.findall(r'\[\[([^\]]+)\]\]', content)
                md_links = re.findall(r'\[([^\]]*)\]\(([^)]+)\)', content)
                
                for link in wiki_links:
                    clean_link = link.split('|')[0].split('#')[0].strip()
                    if clean_link not in link_map:
                        link_map[clean_link] = []
                    link_map[clean_link].append(str(md_file))
                
                for text, target in md_links:
                    if not target.startswith(('http', 'mailto', 'ftp')):
                        if target not in link_map:
                            link_map[target] = []
                        link_map[target].append(str(md_file))
                        
            except Exception as e:
                print(f"Warning: Could not analyze {md_file}: {e}")
        
        # Store patterns in database
        self._store_learned_patterns(link_map, concept_map)
        return link_map
    
    def _extract_concepts(self, file_path: Path, content: str) -> List[str]:
        """Extract key concepts from file path and content"""
        concepts = []
        
        # Extract from filename
        filename_concepts = re.findall(r'[A-Z][a-z]+|[a-z]+', file_path.stem)
        concepts.extend(filename_concepts)
        
        # Extract from headers
        headers = re.findall(r'^#+\s+(.+)$', content, re.MULTILINE)
        for header in headers:
            header_concepts = re.findall(r'[A-Z][a-z]+|[a-z]+', header)
            concepts.extend(header_concepts)
        
        # Extract key terms (simple heuristic)
        key_terms = re.findall(r'\b[A-Z][A-Za-z]*(?:-[A-Z][A-Za-z]*)*\b', content)
        concepts.extend(key_terms[:20])  # Limit to avoid noise
        
        return list(set(concepts))
    
    def _store_learned_patterns(self, link_map: Dict, concept_map: Dict):
        """Store learned patterns in database"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        for target, sources in link_map.items():
            if len(sources) > 1:  # Pattern if used in multiple files
                # Find common concepts in source files
                common_concepts = set()
                for source in sources:
                    if source in concept_map:
                        if not common_concepts:
                            common_concepts = set(concept_map[source])
                        else:
                            common_concepts &= set(concept_map[source])
                
                if common_concepts:
                    pattern = f"concepts:{','.join(sorted(common_concepts))}"
                    cursor.execute('''
                        INSERT OR REPLACE INTO link_patterns 
                        (pattern, target_template, usage_count)
                        VALUES (?, ?, ?)
                    ''', (pattern, target, len(sources)))
        
        conn.commit()
        conn.close()
    
    def suggest_fixes_for_broken_links(self, broken_links: List[dict]) -> List[LinkSuggestion]:
        """Generate AI suggestions for broken links"""
        print("🧠 Generating AI-powered link suggestions...")
        suggestions = []
        
        # Load current patterns
        self._load_patterns()
        
        for broken_link in broken_links:
            link_text = broken_link.get('link', '').strip('[]()').split('|')[0]
            file_path = broken_link.get('file', '')
            line_num = broken_link.get('line', 0)
            
            # Multiple suggestion strategies
            suggestions.extend(self._fuzzy_match_suggestions(link_text, file_path, line_num))
            suggestions.extend(self._semantic_suggestions(link_text, file_path, line_num))
            suggestions.extend(self._pattern_based_suggestions(link_text, file_path, line_num))
            
        # Rank and deduplicate suggestions
        return self._rank_suggestions(suggestions)
    
    def _fuzzy_match_suggestions(self, broken_link: str, file_path: str, line_num: int) -> List[LinkSuggestion]:
        """Generate suggestions based on fuzzy string matching"""
        suggestions = []
        
        # Find all existing files
        existing_files = []
        for md_file in self.cortex_path.rglob("*.md"):
            filename = md_file.stem
            existing_files.append((filename, str(md_file)))
        
        # Calculate similarity scores
        for filename, full_path in existing_files:
            similarity = self._calculate_string_similarity(broken_link, filename)
            if similarity > 0.6:  # Threshold for suggestion
                suggestions.append(LinkSuggestion(
                    broken_link=broken_link,
                    suggested_target=filename,
                    confidence=similarity,
                    reasoning=f"Fuzzy match with existing file '{filename}' (similarity: {similarity:.2f})",
                    context=f"Found similar file name",
                    file_path=file_path,
                    line_number=line_num
                ))
        
        return suggestions
    
    def _semantic_suggestions(self, broken_link: str, file_path: str, line_num: int) -> List[LinkSuggestion]:
        """Generate suggestions based on semantic analysis"""
        suggestions = []
        
        try:
            # Read context from the file
            with open(file_path, 'r', encoding='utf-8') as f:
                lines = f.readlines()
                
            # Get context around the broken link
            start = max(0, line_num - 3)
            end = min(len(lines), line_num + 3)
            context = ' '.join(lines[start:end])
            
            # Extract concepts from context
            context_concepts = self._extract_concepts_from_text(context)
            
            # Find files with similar concepts
            for md_file in self.cortex_path.rglob("*.md"):
                try:
                    file_content = md_file.read_text(encoding='utf-8')
                    file_concepts = self._extract_concepts_from_text(file_content)
                    
                    # Calculate concept overlap
                    overlap = len(set(context_concepts) & set(file_concepts))
                    if overlap > 2:  # Reasonable threshold
                        confidence = min(0.8, overlap / 10)  # Scale confidence
                        suggestions.append(LinkSuggestion(
                            broken_link=broken_link,
                            suggested_target=md_file.stem,
                            confidence=confidence,
                            reasoning=f"Semantic similarity: {overlap} shared concepts ({', '.join(list(set(context_concepts) & set(file_concepts))[:3])})",
                            context=context[:200],
                            file_path=file_path,
                            line_number=line_num
                        ))
                        
                except Exception:
                    continue
                    
        except Exception as e:
            print(f"Warning: Could not perform semantic analysis: {e}")
        
        return suggestions
    
    def _pattern_based_suggestions(self, broken_link: str, file_path: str, line_num: int) -> List[LinkSuggestion]:
        """Generate suggestions based on learned patterns"""
        suggestions = []
        
        # Load patterns from database
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT pattern, target_template, usage_count, 
                   CASE WHEN usage_count > 0 THEN success_count * 1.0 / usage_count ELSE 0 END as success_rate
            FROM link_patterns 
            WHERE usage_count > 2 
            ORDER BY usage_count DESC
        ''')
        
        patterns = cursor.fetchall()
        conn.close()
        
        for pattern, target_template, usage_count, success_rate in patterns:
            if self._pattern_matches(pattern, broken_link, file_path):
                confidence = min(0.9, success_rate * 0.8 + (usage_count / 20) * 0.2)
                suggestions.append(LinkSuggestion(
                    broken_link=broken_link,
                    suggested_target=target_template,
                    confidence=confidence,
                    reasoning=f"Pattern match: {pattern} (used {usage_count} times, {success_rate:.1%} success rate)",
                    context=f"Historical pattern",
                    file_path=file_path,
                    line_number=line_num
                ))
        
        return suggestions
    
    def _calculate_string_similarity(self, str1: str, str2: str) -> float:
        """Calculate similarity between two strings"""
        # Simple similarity calculation (can be improved with better algorithms)
        str1, str2 = str1.lower(), str2.lower()
        
        # Exact match
        if str1 == str2:
            return 1.0
        
        # Substring match
        if str1 in str2 or str2 in str1:
            return 0.8
        
        # Word overlap
        words1 = set(re.findall(r'\w+', str1))
        words2 = set(re.findall(r'\w+', str2))
        
        if words1 and words2:
            overlap = len(words1 & words2)
            total = len(words1 | words2)
            return overlap / total
        
        return 0.0
    
    def _extract_concepts_from_text(self, text: str) -> List[str]:
        """Extract concepts from text"""
        # Simple concept extraction - can be enhanced with NLP
        concepts = []
        
        # Technical terms (capitalized words/phrases)
        tech_terms = re.findall(r'\b[A-Z][A-Za-z]*(?:-[A-Z][A-Za-z]*)*\b', text)
        concepts.extend(tech_terms)
        
        # Common domain concepts
        domain_terms = re.findall(r'\b(?:API|REST|JWT|Auth|System|Process|Template|Decision|Pattern|Link|Validation)\b', text, re.IGNORECASE)
        concepts.extend(domain_terms)
        
        return list(set(concepts))
    
    def _pattern_matches(self, pattern: str, broken_link: str, file_path: str) -> bool:
        """Check if a pattern matches the current context"""
        if pattern.startswith("concepts:"):
            concepts = pattern.split("concepts:")[1].split(",")
            file_concepts = self._extract_concepts_from_text(Path(file_path).read_text(encoding='utf-8'))
            return len(set(concepts) & set(file_concepts)) > 0
        
        return False
    
    def _rank_suggestions(self, suggestions: List[LinkSuggestion]) -> List[LinkSuggestion]:
        """Rank suggestions by confidence and deduplicate"""
        # Group by broken_link
        grouped = {}
        for suggestion in suggestions:
            key = (suggestion.broken_link, suggestion.file_path)
            if key not in grouped:
                grouped[key] = []
            grouped[key].append(suggestion)
        
        # Keep top suggestions for each broken link
        final_suggestions = []
        for suggestions_group in grouped.values():
            # Sort by confidence and take top 3
            sorted_suggestions = sorted(suggestions_group, key=lambda s: s.confidence, reverse=True)[:3]
            final_suggestions.extend(sorted_suggestions)
        
        return sorted(final_suggestions, key=lambda s: s.confidence, reverse=True)
    
    def _load_patterns(self):
        """Load learned patterns from database"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('SELECT pattern, target_template, usage_count FROM link_patterns')
        patterns = cursor.fetchall()
        
        for pattern, target_template, usage_count in patterns:
            self.patterns_cache[pattern] = LinkPattern(
                pattern=pattern,
                target_template=target_template,
                usage_count=usage_count,
                success_rate=0.8  # Default, will be calculated based on history
            )
        
        conn.close()
    
    def generate_suggestions_report(self, suggestions: List[LinkSuggestion], output_file: str):
        """Generate a detailed suggestions report"""
        print(f"📋 Generating suggestions report: {output_file}")
        
        with open(output_file, 'w') as f:
            f.write("# AI Link Suggestions Report\n\n")
            f.write(f"**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"**Total Suggestions:** {len(suggestions)}\n\n")
            
            if not suggestions:
                f.write("✅ No broken links found or all links have been resolved!\n")
                return
            
            # Group by file
            by_file = {}
            for suggestion in suggestions:
                file_path = suggestion.file_path
                if file_path not in by_file:
                    by_file[file_path] = []
                by_file[file_path].append(suggestion)
            
            for file_path, file_suggestions in by_file.items():
                f.write(f"## {Path(file_path).name}\n\n")
                f.write(f"**Path:** `{file_path}`\n\n")
                
                for suggestion in file_suggestions:
                    confidence_emoji = "🟢" if suggestion.confidence > 0.8 else "🟡" if suggestion.confidence > 0.6 else "🔴"
                    f.write(f"### {confidence_emoji} Broken Link: `{suggestion.broken_link}`\n\n")
                    f.write(f"- **Line:** {suggestion.line_number}\n")
                    f.write(f"- **Suggested Fix:** `{suggestion.suggested_target}`\n")
                    f.write(f"- **Confidence:** {suggestion.confidence:.1%}\n")
                    f.write(f"- **Reasoning:** {suggestion.reasoning}\n")
                    
                    if suggestion.context:
                        f.write(f"- **Context:** {suggestion.context[:100]}...\n")
                    
                    f.write("\n")
            
            f.write("\n## Application Commands\n\n")
            f.write("To apply these suggestions:\n\n")
            f.write("```bash\n")
            f.write("# Review suggestions\n")
            f.write("./ai-link-advisor.py suggest --review\n\n")
            f.write("# Apply high-confidence suggestions automatically\n")
            f.write("./ai-link-advisor.py apply --confidence 0.8\n\n")
            f.write("# Apply specific suggestion interactively\n")
            f.write("./ai-link-advisor.py apply --interactive\n")
            f.write("```\n")

def main():
    parser = argparse.ArgumentParser(description="Cortex AI Link Advisor")
    parser.add_argument("command", choices=["analyze", "suggest", "apply"], 
                       help="Command to execute")
    parser.add_argument("--cortex-path", default="../cortex", 
                       help="Path to Cortex repository")
    parser.add_argument("--output", default="ai-suggestions.md", 
                       help="Output file for suggestions")
    parser.add_argument("--confidence", type=float, default=0.7, 
                       help="Minimum confidence for suggestions")
    
    args = parser.parse_args()
    
    print("🤖 Cortex AI Link Advisor")
    print("=" * 30)
    
    advisor = AILinkAdvisor(args.cortex_path, ".")
    
    if args.command == "analyze":
        link_patterns = advisor.analyze_existing_links()
        print(f"✅ Analyzed {len(link_patterns)} link patterns")
        
    elif args.command == "suggest":
        # Get broken links from latest report
        latest_report = max(Path("test-results").glob("broken_links_*.json"))
        with open(latest_report) as f:
            data = json.load(f)
            broken_links = data["broken_links"]
        
        if not broken_links:
            print("✅ No broken links found!")
            return
        
        suggestions = advisor.suggest_fixes_for_broken_links(broken_links)
        advisor.generate_suggestions_report(suggestions, args.output)
        
        print(f"🎯 Generated {len(suggestions)} suggestions")
        print(f"📋 Report saved to: {args.output}")
        
    elif args.command == "apply":
        print("🚧 Auto-application coming in Phase 3!")
        print("For now, please review suggestions manually.")

if __name__ == "__main__":
    main()