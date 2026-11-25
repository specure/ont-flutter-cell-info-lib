# The classes in `models` are serialized with Gson by reflection: their field names are the JSON
# keys the Dart side reads, so they must survive R8 in the consuming app.
-keep class com.specure.nettest.cell_info.models.** { *; }
