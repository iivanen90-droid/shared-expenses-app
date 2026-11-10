# Currency catalog for Tricount groups

Use [SIX's ISO 4217 Current Currency & Funds list](https://www.six-group.com/en/products-services/financial-information/market-reference-data/data-standards.html) for active alphabetic codes. [List One XML](https://www.six-group.com/dam/download/financial-information/data-center/iso-currrency/lists/list-one.xml) is the input for catalog updates. The snapshot verified for this feature is dated 2026-09-17.

Keep rows with a three-letter currency code and a numeric minor unit, exclude rows marked as funds, and deduplicate by code. This yields 155 codes in the verified snapshot and excludes precious metals, funds, and special entries without minor units. The catalog does not use the ISO historical list.

Use the `displayName` fields in the English and Ukrainian `currencies.json` files of [Unicode CLDR JSON 49.0.0](https://github.com/unicode-org/cldr-json/releases/tag/49.0.0). The verified ISO snapshot has English names for all 155 codes and Ukrainian names for 154. Use the English name as the fallback for the missing Ukrainian name (`VED`). Include the [Unicode data license](https://github.com/unicode-org/cldr-json/blob/49.0.0/LICENSE) when bundling derived data.

Bundle the resulting catalog with the app so that currency selection works offline. Search the current language's display name and the ISO code. Persist only the ISO code with the group. The catalog contains no exchange rates.
