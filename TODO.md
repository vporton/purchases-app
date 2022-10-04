- Allow to add a place by clicking map (seems not to be supported by Flutter's implementation
  to detect clicks over markers that were not added by ourselves).
- My errors explained in https://stackoverflow.com/a/73749826/856090
- Should ask confirmation when deleting prices?
- Validate that place name or category name is non-empty.
- What to do with duplicate names of objects?
- Use widget keys?
- Help.
- How to dispose `TextEditingController`?
- Initiate Google Maps when clicking by price in category.
- Limit amount of money spent by hiding Google API behind my own proxy server, sell in app
  access to that server.
- Use `ListTile` class where appropriate.
- In a hardly understandable reason, `_SavedPlacesState.places` updates before `updateData()` is
  run, thus preventing updating displayed Saved Places list after editing a place name.
  Also similar error when deleting a place.
- The map does not update markers when creating/deleting places.

See also `TODO` and `FIXME` in the source.