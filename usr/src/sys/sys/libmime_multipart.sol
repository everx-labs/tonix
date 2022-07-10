pragma ton-solidity >= 0.60.0;
library libmime_multipart {

    uint8 constant MULTIPART_alternative  = 1;  // [RFC2046][RFC2045]
    uint8 constant MULTIPART_appledouble  = 2;  // [Patrik_Faltstrom]
    uint8 constant MULTIPART_byteranges   = 3;  // [RFC-ietf-httpbis-semantics-19]
    uint8 constant MULTIPART_digest 	  = 4;  // [RFC2046][RFC2045]
    uint8 constant MULTIPART_encrypted 	  = 5;  // [RFC1847]
    uint8 constant MULTIPART_example 	  = 6;  // [RFC4735]
    uint8 constant MULTIPART_form_data 	  = 7;  // [RFC7578]
    uint8 constant MULTIPART_header_set   = 8;  // [Dave_Crocker]
    uint8 constant MULTIPART_mixed 		  = 9;  // [RFC2046][RFC2045]
    uint8 constant MULTIPART_multilingual = 10; // [RFC8255]
    uint8 constant MULTIPART_parallel 	  = 11; // [RFC2046][RFC2045]
    uint8 constant MULTIPART_related 	  = 12; // [RFC2387]
    uint8 constant MULTIPART_report 	  = 13; // [RFC6522]
    uint8 constant MULTIPART_signed 	  = 14; // [RFC1847]
    uint8 constant MULTIPART_vnd_bint_med_plus = 15; // [Heinz-Peter_Schütz]
    uint8 constant MULTIPART_voice_message = 16; // [RFC3801]
    uint8 constant MULTIPART_x_mixed_replace = 17; // [W3C][Robin_Berjon]
}