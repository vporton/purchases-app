- Allow to add a place by clicking map (seems not to be supported by Flutter's implementation
  to detect clicks over markers that were not added by ourselves).
- My errors explained in https://stackoverflow.com/a/73749826/856090
- Autocomplete search for places.
- Deleting places and categories, deleting prices.
- Validate that place name or category name is non-empty.
- Validate price entry textfield.
- What to do with duplicate names of objects?
- Use widget keys?
- Help.
- How to dispose `TextEditingController`?
- It allows to enter only whole numbers as prices.
- Added place does not appear in Saved Places without "refresh" (closing Saved Places).
- Initiate Google Maps when clicking by price in category.
- Don't store data more than 30 days as per Google Maps license.
- Limit amount of money spent by hiding Google API behind my own proxy server, sell in app
  access to that server.
- Use `ListTile` class where appropriate.

See also `TODO` and `FIXME` in the source.