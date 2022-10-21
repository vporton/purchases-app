- Allow to add a place by clicking map (seems not to be supported by Flutter's implementation
  to detect clicks over markers that were not added by ourselves).
- My errors explained in https://stackoverflow.com/a/73749826/856090
- Should ask confirmation when deleting prices?
- Validate that place name or category name is non-empty.
- What to do with duplicate names of objects?
- Use widget keys?
- Help.
- How to dispose `TextEditingController`?
- Limit amount of money spent by hiding Google API behind my own proxy server, sell in app
  access to that server.
- Use `ListTile` class where appropriate.
- The map does not update markers when creating/deleting places.
- Interchange of prices between users.
- Entering prices by shops.
  - Shop authenticates to Google Business for verification and then
    edits categories and prices in the same way as a user (except that the shop is fixed).
    Afterward, a user can retrieve shop data and include kinds of products from the shop
    in hist category structure, except than can't change internal relations between shop-specific
    categories.

See also `TODO` and `FIXME` in the source.