# nostr-kit

nostr-kit is a high performance nostr library designed for client and server-side uses. the library is primarily an event-driven networking engine, but comes with many structures and protocols around nostr primitives and the cryptography behind them. the goal of nostr-kit is to eliminate the many layers of mechanical networking and cryptographic code that burdens any nostr application, **whether they be socially based applications or not**.

unlike *most* "fast and cheap" libraries for high-level languages, `nostr-kit` is radically low-level and integrated.

with a protocol-oriented design philosophy to its frontend facade, `nostr-kit` is the best platform to build any open-ended information solution with nostr.

### Show me the NIPs

nostr-kit does not strive to implement every NIP under the sun. given the open-ended and application agnostic intent of nostr-kits design, it makes sense to leave many NIPs up to various application developers to (not) implement, as they see fit.

however, there are still many foundational NIPs that nostr-kit implements. amongst these NIPs are:

- NIP-01
- NIP-04 (a shitty NIP that I hope to depricate for better NIPs one day)
- NIP-05
- NIP-20
- NIP-42

### NOICE

This project is still in its (extremely early) infancy, and while functional for limited uses (such as posting events), the API around doing anything functional is almost GUARANTEED to change over the coming weeks and months. These API's may even change multiple times.

Production consideration of this framework should NOT be seriously considered until the 1.0.0 release.