# App Store Connect — screens, fields and the answers that fit (as of 2026-11)

Recorded while submitting MA: SplitFlap (iOS/iPadOS, Tauri, offline, sound,
no account, no in-app purchase, paid up front). Re-check anything here
against the live screen; Apple renames and moves fields.

## Where each field lives

| Field | Screen | Change needs a new version? |
|---|---|---|
| Name, subtitle | App Information (per locale) | yes |
| Category | App Information | no |
| Age rating | App Information | no |
| Content rights | App Information | no |
| Privacy policy URL, User Privacy Choices URL | App Privacy | no |
| Price, availability, Mac (Apple silicon), Apple School Manager discount | Pricing and Availability | **no** |
| Promotional text | version page (per locale) | **no** |
| Description, keywords, support URL, marketing URL | version page (per locale) | yes |
| Copyright | version page | yes |
| Screenshots, previews, Header and Search Results asset | version page | yes |
| App Review Information (contact, Notes) | version page | — |
| Build | version page | — |
| App icon | **not in ASC** — comes from the build's asset catalog (1024×1024, no alpha) | — |
| EU trader status (DSA) | Business → Agreements → Compliance | — |

## Age rating (2025 questionnaire)

For an offline tool with no web view, no user content, no chat and no ads,
every answer is No / None, which gives **4+**. The newer questions are:
Parental Controls, Age Assurance, Unrestricted Web Access,
User-Generated Content, Social Media, social media for under-13s,
Messaging, Advertising.

## Pricing and Availability

- Apple School Manager volume discount (50% off for 20+ copies): leave on.
- "Make this app available on Mac (Apple silicon)": leave off until the iPad
  build has been checked on a Mac (window resize, sound, swipe via
  trackpad, screen staying on). It can be turned on later without review.
  If a separate native Mac app ships later, it has to be off again.

## EU Digital Services Act (trader status)

- A trader must publish address, phone and email; they appear **only on EU
  storefronts**. The seller name appears everywhere regardless.
- Until the status is declared, the app is **not distributed in the EU**.
  Other regions are unaffected, so deferring is a valid choice. Track it
  as an issue.

## Version page fields

- **Copyright**: `YYYY Name` (e.g. `2026 Tea / Simulation`). No ©, no URL.
  Keep the footers of the support and privacy pages on the same name.
- **Marketing URL**: optional. Leave blank if the only site is the app
  itself (a free web version is not a marketing page).
- **Support URL**: a page on your own domain with a contact address and a
  link to the privacy policy. Keep it minimal; troubleshooting sections age
  badly.
- **Routing App Coverage File**: only for navigation apps. Leave empty.
- **App Review contact phone**: international format, `+81` then the
  number without its leading 0.
- **Export compliance**: set `ITSAppUsesNonExemptEncryption = false` in
  Info.plist when the app uses only exempt encryption (HTTPS); the question
  then does not appear per build.

## Media slots and sizes

Required now:

| Slot | Screenshot sizes (landscape / portrait) | Preview sizes |
|---|---|---|
| iPhone with Dynamic Island (medium display), 6.1"/6.3" | 2622×1206 or 2556×1179 / 1206×2622 or 1179×2556 | 1920×886 / 886×1920 |
| iPad 13" | 2752×2064 or 2732×2048 / 2064×2752 or 2048×2732 | 1600×1200 / 1200×1600 |

- The medium iPhone media is used for **all iPhone sizes and all locales**
  unless you add more. One set is enough for a first submission.
- iPhone Duo and Apple Watch slots: leave empty unless the app supports
  them. (Duo reportedly becomes required later; unverified.)
- **Header and Search Results** (iOS 27): one optional asset shared by
  iPhone and iPad, 5244×2950, 3840×2560 or 1920×1280. If it is empty, search
  results show the app previews and screenshots instead. It cannot be set
  for search results only. Leave it empty unless you want a separate
  header image.

## Support email without a mail server

Cloudflare Email Routing forwards `support@<domain>` to Gmail (receive).
To reply from that address, add it in Gmail → "Send mail as" with
`smtp.gmail.com` and an app password, and add `include:_spf.google.com` to
the domain's SPF record. Never ask the owner to paste the app password into
the chat. With iCloud+, custom domain mail does both in one setup but
cannot coexist with Email Routing.

## Audio apps and review

An app whose main function is sound and which plays in Silent mode should
set the audio session natively (`.playback` + `.mixWithOthers`), so it
does not stop the user's music. Say so in the review notes. Test on a
device with music playing, including the **relative loudness**: a master
gain tuned for playing alone can be inaudible next to music.
