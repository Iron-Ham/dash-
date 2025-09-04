const fs = require('fs');
const path = require('path');

// Simple test to validate markdown files exist and are readable
function testMarkdownFiles() {
    const files = ['readme.md', '1.3.0.md', 'newfile.md'];
    let passed = 0;
    let failed = 0;
    
    console.log('Running markdown validation tests...\n');
    
    files.forEach(file => {
        try {
            if (fs.existsSync(file)) {
                const content = fs.readFileSync(file, 'utf8');
                if (content.length > 0) {
                    console.log(`✓ ${file} - exists and has content`);
                    passed++;
                } else {
                    console.log(`✗ ${file} - exists but is empty`);
                    failed++;
                }
            } else {
                console.log(`✗ ${file} - does not exist`);
                failed++;
            }
        } catch (error) {
            console.log(`✗ ${file} - error reading file: ${error.message}`);
            failed++;
        }
    });
    
    console.log(`\nTest Results: ${passed} passed, ${failed} failed`);
    
    if (failed > 0) {
        process.exit(1);
    } else {
        console.log('All tests passed!');
        process.exit(0);
    }
}

if (require.main === module) {
    testMarkdownFiles();
}

module.exports = { testMarkdownFiles };