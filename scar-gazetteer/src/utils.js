import { byNumeric as isoCountryByNumeric } from 'iso-country-codes'

export function getNameForNumericIsoCountryCode(code) {
    code = String(code).padStart(3, '0')
    if (Object.prototype.hasOwnProperty.call(isoCountryByNumeric, code)) {
        return isoCountryByNumeric[code].name
    }

    console.error(`Unknown ISO country code: '${code}'`)
}