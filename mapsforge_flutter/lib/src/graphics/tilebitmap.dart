import 'bitmap.dart';

abstract class TileBitmap extends Bitmap {
/**
 * Returns the timestamp of the tile in milliseconds since January 1, 1970 GMT or 0 if this timestamp is unknown.
 * <p/>
 * The timestamp indicates when the tile was created and can be used together with a TTL in order to determine
 * whether to treat it as expired.
 */
  int? getTimestamp();

/**
 * Whether the TileBitmap has expired.
 * <p/>
 * When a tile has expired, the requester should try to replace it with a fresh copy as soon as possible. The
 * expired tile may still be displayed to the user until the fresh copy is available. This may be desirable if
 * obtaining a fresh copy is time-consuming or a fresh copy is currently unavailable (e.g. because no network
 * connection is available for a {@link org.mapsforge.map.layer.download.tilesource.TileSource}).
 *
 * @return {@code true} if expired, {@code false} otherwise.
 */
  bool? isExpired();

/**
 * Sets the timestamp when this tile will be expired in milliseconds since January 1, 1970 GMT or 0 if this
 * timestamp is unknown.
 * <p/>
 * The timestamp indicates when the tile should be treated it as expired, i.e. {@link #isExpired()} will return
 * {@code true}. For a downloaded tile, pass the value returned by
 * {@link java.net.HttpURLConnection#getExpiration()}, if set by the server. In all other cases you can pass current
 * time plus a fixed TTL in order to have the tile expire after the specified time.
 */
  void setExpiration(int expiration);

/**
 * Sets the timestamp of the tile in milliseconds since January 1, 1970 GMT.
 * <p/>
 * The timestamp indicates when the information to create the tile was last retrieved from the source. It can be
 * used together with a TTL in order to determine whether to treat it as expired.
 * <p/>
 * The timestamp of a locally rendered tile should be set to the timestamp of the map database used to render it, as
 * returned by {@link org.mapsforge.map.reader.header.MapFileInfo#mapDate}. For a tile read from a disk cache, it
 * should be the file's timestamp. In all other cases (including downloaded tiles), the timestamp should be set to
 * wall clock time (as returned by {@link java.lang.System#currentTimeMillis()}) when the tile is created.
 * <p/>
 * Classes that implement this interface should call {@link java.lang.System#currentTimeMillis()} upon creating an
 * instance, store the result and return it unless {@code setTimestamp()} has been called for that instance.
 */
  void setTimestamp(int timestamp);
}
