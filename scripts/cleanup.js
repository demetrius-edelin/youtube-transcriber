const fs = require('fs');
const path = require('path');

// Get input filename from CLI argument
const inputFile = process.argv[2];
if (!inputFile) {
  console.error('Usage: node cleanup.js <inputfile>');
  process.exit(1);
}

// Read transcript from file
const input = fs.readFileSync(inputFile, 'utf8');

// Check if we have timestamp format or just one phrase per line
const hasTimestamps = input.match(/\[\d{2}:\d{2}:\d{2}\.\d{3}\]/);

let cleaned;

if (hasTimestamps) {
  // Original timestamp format processing
  cleaned = input
    // Remove timestamps - match [00:00:00.000] format
    .replace(/\[\d{2}:\d{2}:\d{2}\.\d{3}\]\s*/g, '')
    
    // Join lines that belong to the same paragraph (not after punctuation)
    .replace(/([^.?!])\n\s*/g, '$1 ')
    
    // Detect potential speaker changes using universal patterns
    // Look for question starters or common dialogue indicators
    .replace(/\n(What|Why|How|When|Where|Who|Is|Can|Could|Do|Does|If|Please)/g, '\n\n$1')
    
    // Add double newline after sentence-ending punctuation for paragraph breaks
    // but only when followed by a capital letter indicating a new thought
    .replace(/([.?!])\s+(?=[A-Z])/g, '$1\n\n')
    
    // Add paragraph breaks after common discourse markers and conjunctions 
    // that often indicate topic shifts
    .replace(/(\. )(First|However|Furthermore|Therefore|Moreover|In addition|On the other hand|Nevertheless|Consequently|Thus|So|Indeed|Basically|Actually)/g, '$1\n\n$2');
} else {
  // For one phrase per line format (without timestamps)
  cleaned = input
    // Join sentences that are split across lines (not ending with punctuation)
    .replace(/([^.?!,])\n/g, '$1 ')
    
    // Keep proper paragraph breaks on sentences that end with punctuation
    .replace(/([.?!])\n/g, '$1\n\n')
    
    // Add paragraph breaks after transition phrases
    .replace(/(\. )(First|However|Furthermore|Therefore|Moreover|In addition|On the other hand|Nevertheless|Consequently|Thus|So|Indeed|Basically|Actually|Dada)/g, '$1\n\n$2')
    
    // Create proper paragraph breaks for questions
    .replace(/\n(What|Why|How|When|Where|Who|Is|Can|Could|Do|Does|If|Please)/g, '\n\n$1');
}

// Common processing for both formats
cleaned = cleaned
  // Remove empty lines
  .replace(/\n{3,}/g, '\n\n')
  // Remove multiple spaces
  .replace(/ +/g, ' ')
  .trim();

const ext = path.extname(inputFile);
const base = path.basename(inputFile, ext);
const outputFile = `${base}_cleaned${ext}`;

fs.writeFileSync(outputFile, cleaned);

console.log(`Transcript cleaned and saved to ${outputFile}`);
console.log('Text formatted into paragraphs.');