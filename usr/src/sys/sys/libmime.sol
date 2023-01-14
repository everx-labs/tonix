pragma ton-solidity >= 0.60.0;
import "libstring.sol";
import "libmime_audio.sol";
import "libmime_image.sol";
import "libmime_video.sol";
import "libmime_message.sol";
import "libmime_multipart.sol";
import "libmime_font.sol";
import "libmime_text.sol";
import "libmime_model.sol";

library libmime {

    using libstring for string;

    uint8 constant APP     = 1; // Any kind of binary data that doesn't fall explicitly into one of the other types; either data that will be executed or interpreted in some way or binary data that requires a specific application or category of application to use. Generic binary data (or binary data whose true type is unknown) is application/octet-stream. Other common examples include application/pdf, application/pkcs8, and application/zip
    uint8 constant AUDIO   = 2; // Audio or music data. Examples include audio/mpeg, audio/vorbis
    uint8 constant EXAMPLE = 3; // Reserved for use as a placeholder in examples showing how to use MIME types. These should never be used outside of sample code listings and documentation. example can also be used as a subtype; for instance, in an example related to working with audio on the web, the MIME type audio/example can be used to indicate that the type is a placeholder and should be replaced with an appropriate one when using the code in the real world.
    uint8 constant FONT    = 4; // Font/typeface data. Common examples include font/woff, font/ttf, and font/otf
    uint8 constant IMAGE   = 5; // Image or graphical data including both bitmap and vector still images as well as animated versions of still image formats such as animated GIF or APNG. Common examples are image/jpeg, image/png, and image/svg+xml
    uint8 constant MODEL   = 6; // Model data for a 3D object or scene. Examples include model/3mf and model/vrml
    uint8 constant TEXT    = 7; // Text-only data including any human-readable content, source code, or textual data such as comma-separated value (CSV) formatted data. Examples include: text/plain, text/csv, and text/html
    uint8 constant VIDEO   = 8; // Video data or files, such as MP4 movies (video/mp4)
    uint8 constant MESSAGE = 9; // A message that encapsulates other messages. This can be used, for instance, to represent an email that includes a forwarded message as part of its data, or to allow sending very large messages in chunks as if it were multiple messages. Examples include message/rfc822 (for forwarded or replied-to message quoting) and message/partial to allow breaking a large message into smaller ones automatically to be reassembled by the recipient
    uint8 constant MULTI   = 10; // Data that is comprised of multiple components which may individually have different MIME types. Examples include multipart/form-data (for data produced using the FormData API) and multipart/byteranges (defined in RFC 7233: 5.4.1 and used with HTTP's 206 "Partial Content" response returned when the fetched data is only part of the content, such as is delivered using the Range header)

    uint8 constant APP_X_EXECUTABLE = 1;
    uint8 constant APP_GRAPHQL      = 2;
    uint8 constant APP_JAVASCRIPT   = 3;
    uint8 constant APP_JSON         = 4;
    uint8 constant APP_LD_JSON      = 5;
    uint8 constant APP_FEED_JSON    = 6;
    uint8 constant APP_MSWORD       = 7;
    uint8 constant APP_PDF          = 8;
    uint8 constant APP_SQL          = 9;
    uint8 constant APP_URLENCODED   = 10;
    uint8 constant APP_XML          = 11;
    uint8 constant APP_ZIP          = 12;
    uint8 constant APP_ZSTD         = 13;
    uint8 constant APP_MACBINARY    = 14;

    uint8 constant AUDIO_MPEG = 1;
    uint8 constant AUDIO_OGG = 2;

    uint8 constant IMAGE_APNG = 1;
    uint8 constant IMAGE_AVIF = 2;
    uint8 constant IMAGE_FLIF = 3;
    uint8 constant IMAGE_GIF = 4;
    uint8 constant IMAGE_JPEG = 5;
    uint8 constant IMAGE_JXL = 6;
    uint8 constant IMAGE_PNG = 7;
    uint8 constant IMAGE_SVG_XML = 8;
    uint8 constant IMAGE_WEBP = 10;
    uint8 constant IMAGE_X_MNG = 11;

    uint8 constant TEXT_CSS = 1;
    uint8 constant TEXT_CSV = 2;
    uint8 constant TEXT_HTML = 3;
    uint8 constant TEXT_PHP = 4;
    uint8 constant TEXT_PLAIN = 5;
    uint8 constant TEXT_X_C = 6;
    uint8 constant TEXT_XML = 7;

    uint8 constant MULTI_FORM_DATA = 1;

    uint8 constant CHARSET = 1;

    uint8 constant CHARSET_BINARY = 1;
    uint8 constant CHARSET_ASCII  = 2;

    function parse_file_info(string s) internal returns (uint type_id, uint subtype_id, uint charset) {
        (string minfo, string csinfo) = s.csplit(';');
        (string smtype, string smsubtype) = minfo.csplit('/');
        (uint umtype, uint umsubtype) = (mime_type_id(smtype), mime_subtype_id(smsubtype));
        (string sparam, string sparamval) = csinfo.csplit('=');
        (uint uparam, uint uparamval) = ((param_string_to_id(sparam.substr(1)), param_value_string_to_id(sparamval.substr(0, sparamval.byteLength() - 1))));
        if (uparam + umtype > 0)
            return (umtype, umsubtype, uparamval);
    }

    function print_type(uint type_id, uint subtype_id, uint charset) internal returns (string) {

    }
    function param_string_to_id(string s) internal returns (uint) {
        if (s == "charset") return CHARSET;
    }

    function param_string(uint param) internal returns (string) {
        if (param == CHARSET) return "charset";
    }

    function param_value_string_to_id(string s) internal returns (uint) {
        if (s == "binary") return CHARSET_BINARY;
        if (s == "us-ascii") return CHARSET_ASCII;
    }

    function param_value_string(uint val) internal returns (string) {
        if (val == CHARSET_BINARY) return "binary";
        if (val == CHARSET_ASCII) return "us-ascii";
    }

    function mime_type_id(string s) internal returns (uint) {
        if (s == "application") return APP;
        if (s == "audio") return AUDIO;
        if (s == "example") return EXAMPLE;
        if (s == "font") return FONT;
        if (s == "image") return IMAGE;
        if (s == "model") return MODEL;
        if (s == "text") return TEXT;
        if (s == "video") return VIDEO;
        if (s == "message") return MESSAGE;
        if (s == "multipart") return MULTI;
    }

    function mime_subtype_id(string s) internal returns (uint) {
        if (s == "x-executable") return APP_X_EXECUTABLE;
        if (s == "graphql") return APP_GRAPHQL;
        if (s == "javascript") return APP_JAVASCRIPT;
        if (s == "json") return APP_JSON;
        if (s == "ld+json") return APP_LD_JSON;
        if (s == "feed+json") return APP_FEED_JSON;
        if (s == "msword") return APP_MSWORD;
        if (s == "pdf") return APP_PDF;
        if (s == "sql") return APP_SQL;
        if (s == "x-www-form-urlencoded") return APP_URLENCODED;
        if (s == "xml") return APP_XML;
        if (s == "zip") return APP_ZIP;
        if (s == "zstd") return APP_ZSTD;
        if (s == "applefile") return APP_MACBINARY;

        if (s == "mpeg") return AUDIO_MPEG;
        if (s == "ogg") return AUDIO_OGG;

        if (s == "apng") return IMAGE_APNG;
        if (s == "avif") return IMAGE_AVIF;
        if (s == "flif") return IMAGE_FLIF;
        if (s == "gif") return IMAGE_GIF;
        if (s == "jpeg") return IMAGE_JPEG;
        if (s == "jxl") return IMAGE_JXL;
        if (s == "png") return IMAGE_PNG;
        if (s == "svg+xml") return IMAGE_SVG_XML;
        if (s == "webp") return IMAGE_WEBP;
        if (s == "xmng") return IMAGE_X_MNG;

        if (s == "css") return TEXT_CSS;
        if (s == "csv") return TEXT_CSV;
        if (s == "html") return TEXT_HTML;
        if (s == "php") return TEXT_PHP;
        if (s == "plain") return TEXT_PLAIN;
        if (s == "xml") return TEXT_XML;
        if (s == "x-c") return TEXT_X_C;

        if (s == "form-data") return MULTI_FORM_DATA;
    }

    function mime_type_to_string(uint type_id, uint subtype_id) internal returns (string) {
        return mime_type_string(type_id) + "/" + mime_subtype_string(type_id, subtype_id);
    }

    function mime_param_to_string(uint param_id, uint param_val) internal returns (string) {
        return param_string(param_id) + "=" + param_value_string(param_val);
    }

    function mime_type_string(uint type_id) internal returns (string) {
        if (type_id == APP) return "application";
        if (type_id == AUDIO) return "audio";
        if (type_id == EXAMPLE) return "example";
        if (type_id == FONT) return "font";
        if (type_id == IMAGE) return "image";
        if (type_id == MODEL) return "model";
        if (type_id == TEXT) return "text";
        if (type_id == VIDEO) return "video";
        if (type_id == MESSAGE) return "message";
        if (type_id == MULTI) return "multipart";
    }

    function mime_subtype_string(uint type_id, uint subtype_id) internal returns (string) {
        if (type_id == APP) {
            if (subtype_id == APP_X_EXECUTABLE) return "x-executable";
            if (subtype_id == APP_GRAPHQL) return "graphql";
            if (subtype_id == APP_JAVASCRIPT) return "javascript";
            if (subtype_id == APP_JSON) return "json";
            if (subtype_id == APP_LD_JSON) return "ld+json";
            if (subtype_id == APP_FEED_JSON) return "feed+json";
            if (subtype_id == APP_MSWORD) return "msword";
            if (subtype_id == APP_PDF) return "pdf";
            if (subtype_id == APP_SQL) return "sql";
            if (subtype_id == APP_URLENCODED) return "x-www-form-urlencoded";
            if (subtype_id == APP_XML) return "xml";
            if (subtype_id == APP_ZIP) return "zip";
            if (subtype_id == APP_ZSTD) return "zstd";
            if (subtype_id == APP_MACBINARY) return "applefile";
        }

        if (type_id == AUDIO) {
            if (subtype_id == AUDIO_MPEG) return "mpeg";
            if (subtype_id == AUDIO_OGG) return "ogg";
        }
        if (type_id == EXAMPLE) {
        }

        if (type_id == FONT) {

        }
        if (type_id == IMAGE) {
            if (subtype_id == IMAGE_APNG) return "apng";
            if (subtype_id == IMAGE_AVIF) return "avif";
            if (subtype_id == IMAGE_FLIF) return "flif";
            if (subtype_id == IMAGE_GIF) return "gif";
            if (subtype_id == IMAGE_JPEG) return "jpeg";
            if (subtype_id == IMAGE_JXL) return "jxl";
            if (subtype_id == IMAGE_PNG) return "png";
            if (subtype_id == IMAGE_SVG_XML) return "svg+xml";
            if (subtype_id == IMAGE_WEBP) return "webp";
            if (subtype_id == IMAGE_X_MNG) return "xmng";
        }
        if (type_id == MODEL) {

        }
        if (type_id == TEXT) {
            if (subtype_id == TEXT_CSS) return "css";
            if (subtype_id == TEXT_CSV) return "csv";
            if (subtype_id == TEXT_HTML) return "html";
            if (subtype_id == TEXT_PHP) return "php";
            if (subtype_id == TEXT_PLAIN) return "plain";
            if (subtype_id == TEXT_XML) return "xml";
            if (subtype_id == TEXT_X_C) return "x-c";
        }
        if (type_id == VIDEO) {

        }
        if (type_id == MESSAGE) {

        }
        if (type_id == MULTI) {
            if (subtype_id == MULTI_FORM_DATA) return "form-data";
        }
    }
}