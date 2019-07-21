function hilite(code) {
    const LIT = '<span class="lit">$&</span>';
    const VAR = '<span class="var">$&</span>';
    const KEY = '<span class="key">$&</span>';

    return code.replace('&', '&amp;')
               .replace('<', '&lt;')
               .replace('>', '&gt;')
               .replace(/"(\\.|[^"])*"/g, LIT)
               .replace(/'(\\.|[^'])*'/g, LIT)
               .replace(/(?:[\$\%\@]|\&amp;)\^?\w+/g, VAR)
               .replace(/\b\d+/g, LIT)
               .replace(/(^|\n)\s*(sub|proto|multi|my|state|given|for)\b/g, KEY)
               .replace(/\s+for\s+/g, KEY);
}

addEventListener('DOMContentLoaded', function() {
    for(let block of document.getElementsByTagName('code')) {
        block.innerHTML = hilite(block.innerText);
    }
});
