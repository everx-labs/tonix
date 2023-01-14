pragma ton-solidity >= 0.51.0;

contract MIME {

    uint8 constant TYPE_APPLICATION = 1; //Any kind of binary data that doesn't fall explicitly into one of the other types; either data that will be executed or interpreted in some way or binary data that requires a specific application or category of application to use. Generic binary data (or binary data whose true type is unknown) is application/octet-stream. Other common examples include application/pdf, application/pkcs8, and application/zip
    uint8 constant TYPE_AUDIO = 2;  // Audio or music data. Examples include audio/mpeg, audio/vorbis
    uint8 constant TYPE_EXAMPLE = 3; //    Reserved for use as a placeholder in examples showing how to use MIME types. These should never be used outside of sample code listings and documentation. example can also be used as a subtype; for instance, in an example related to working with audio on the web, the MIME type audio/example can be used to indicate that the type is a placeholder and should be replaced with an appropriate one when using the code in the real world.
    uint8 constant TYPE_FONT = 4; // Font/typeface data. Common examples include font/woff, font/ttf, and font/otf
    uint8 constant TYPE_IMAGE = 5; // Image or graphical data including both bitmap and vector still images as well as animated versions of still image formats such as animated GIF or APNG. Common examples are image/jpeg, image/png, and image/svg+xml
    uint8 constant TYPE_MODEL = 6;  // Model data for a 3D object or scene. Examples include model/3mf and model/vrml
    uint8 constant TYPE_TEXT = 7; // Text-only data including any human-readable content, source code, or textual data such as comma-separated value (CSV) formatted data. Examples include: text/plain, text/csv, and text/html
    uint8 constant TYPE_VIDEO = 8; // Video data or files, such as MP4 movies (video/mp4)
    uint8 constant TYPE_MESSAGE = 9; // A message that encapsulates other messages. This can be used, for instance, to represent an email that includes a forwarded message as part of its data, or to allow sending very large messages in chunks as if it were multiple messages. Examples include message/rfc822 (for forwarded or replied-to message quoting) and message/partial to allow breaking a large message into smaller ones automatically to be reassembled by the recipient
    uint8 constant TYPE_MULTIPART = 10; // Data that is comprised of multiple components which may individually have different MIME types. Examples include multipart/form-data (for data produced using the FormData API) and multipart/byteranges (defined in RFC 7233: 5.4.1 and used with HTTP's 206 "Partial Content" response returned when the fetched data is only part of the content, such as is delivered using the Range header)

    uint8 constant SUBTYPE_APPLICATION_X_EXECUTABLE = 1;
    uint8 constant SUBTYPE_APPLICATION_GRAPHQL = 2;
    uint8 constant SUBTYPE_APPLICATION_JAVASCRIPT = 3;
    uint8 constant SUBTYPE_APPLICATION_JSON= 4;
    uint8 constant SUBTYPE_APPLICATION_LD_JSON = 5;
    uint8 constant SUBTYPE_APPLICATION_FEED_JSON = 6;
    uint8 constant SUBTYPE_APPLICATION_MSWORD = 7;
    uint8 constant SUBTYPE_APPLICATION_PDF = 8;
    uint8 constant SUBTYPE_APPLICATION_SQL = 9;
    uint8 constant SUBTYPE_APPLICATION_X_WWW_FORM_URLENCODED = 10;
    uint8 constant SUBTYPE_APPLICATION_XML = 11;
    uint8 constant SUBTYPE_APPLICATION_ZIP = 12;
    uint8 constant SUBTYPE_APPLICATION_ZSTD = 13;
    uint8 constant SUBTYPE_APPLICATION_MACBINARY = 14;

    uint8 constant SUBTYPE_AUDIO_MPEG = 1;
    uint8 constant SUBTYPE_AUDIO_OGG = 2;


    uint8 constant SUBTYPE_IMAGE_APNG = 1;
    uint8 constant SUBTYPE_IMAGE_AVIF = 2;
    uint8 constant SUBTYPE_IMAGE_FLIF = 3;
    uint8 constant SUBTYPE_IMAGE_GIF = 4;
    uint8 constant SUBTYPE_IMAGE_JPEG = 5;
    uint8 constant SUBTYPE_IMAGE_JXL = 6;
    uint8 constant SUBTYPE_IMAGE_PNG = 7;
    uint8 constant SUBTYPE_IMAGE_SVG_XML = 8;
    uint8 constant SUBTYPE_IMAGE_WEBP = 9;
    uint8 constant SUBTYPE_IMAGE_X_MNG = 10;

    uint8 constant SUBTYPE_TEXT_CSS = 1;
    uint8 constant SUBTYPE_TEXT_CSV = 2;
    uint8 constant SUBTYPE_TEXT_HTML = 3;
    uint8 constant SUBTYPE_TEXT_PHP = 4;
    uint8 constant SUBTYPE_TEXT_PLAIN = 5;
    uint8 constant SUBTYPE_TEXT_XML = 6;

    uint8 constant SUBTYPE_MULTIPART_FORM_DATA = 1;
}