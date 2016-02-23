import postcss from 'postcss'
import { readFileSync as slurp } from 'fs'
import { resolve, isAbsolute } from 'path'
import { parse as parseUrl } from 'url'
import { default as rebaseUrl } from 'postcss-url'

export default function rebase(pkg, opts, filename) {
  return postcss([
      rebaseUrl({
        url: (url, decl, from, dirname, to, options, result) => {
          let parsed = parseUrl(url, true, true)
          
          if (parsed.host || isAbsolute(parsed.path)) {
            return url
          } else {
            let resolved = pkg.relative(resolve(pkg.root, opts.lib, parsed.path))
            return resolved.replace(/\\/g, '/')
          }
        }
      })
    ]).process(slurp(filename, 'utf8'))
}