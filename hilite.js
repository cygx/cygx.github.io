function hilite(code) {
    const LIT = '<span class="lit">$&</span>';
    const VAR = '<span class="var">$&</span>';
    const KEY = '<span class="key">$&</span>';

    return code.replace('&', '&#38;')
               .replace('<', '&#60;')
               .replace('>', '&#62;')
               .replace(/"(\\.|[^"])*"/g, LIT)
               .replace(/'(\\.|[^'])*'/g, LIT)
               .replace(/[\$\&\%\@]\^?\w+/g, VAR)
               .replace(/\b\d+/g, LIT)
               .replace(/(^|\n)\s*(sub|proto|multi|my|state|given|for)\b/g, KEY)
               .replace(/\s+for\s+/g, KEY);
}

addEventListener('DOMContentLoaded', function() {
    for(let block of document.getElementsByTagName('code')) {
        block.innerHTML = hilite(block.innerText);
    }
});
