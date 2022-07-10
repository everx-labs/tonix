pragma ton-solidity >= 0.60.0;
library libmime_audio {
    uint8 constant AUDIO   = 2;
    uint8 constant AUDIO_1d_interleaved_parityfec = 1; // [RFC6015]
    uint8 constant AUDIO_32kadpcm 	  = 2; // [RFC3802][RFC2421]
    uint8 constant AUDIO_3gpp 	 	  = 3; // [RFC3839][RFC6381]
    uint8 constant AUDIO_3gpp2 	      = 4; // [RFC4393][RFC6381]
    uint8 constant AUDIO_aac 	      = 5; // [ISO-IEC_JTC1][Max_Neuendorf]
    uint8 constant AUDIO_ac3 	      = 6; // [RFC4184]
    uint8 constant AUDIO_AMR 	      = 7; // [RFC4867]
    uint8 constant AUDIO_AMR_WB 	  = 8; // [RFC4867]
    uint8 constant AUDIO_amr_wb_plus  = 9; // [RFC4352]
    uint8 constant AUDIO_aptx 	      = 10; // [RFC7310]
    uint8 constant AUDIO_asc 	 	  = 11; // [RFC6295]
    uint8 constant AUDIO_ATRAC_ADVANCED_LOSSLESS = 12; // [RFC5584]
    uint8 constant AUDIO_ATRAC_X 	  = 13; // [RFC5584]
    uint8 constant AUDIO_ATRAC3 	  = 14; // [RFC5584]
    uint8 constant AUDIO_basic 	 	  = 15; // [RFC2045][RFC2046]
    uint8 constant AUDIO_BV16 	      = 16; // [RFC4298]
    uint8 constant AUDIO_BV32 	      = 17; // [RFC4298]
    uint8 constant AUDIO_clearmode    = 18; // [RFC4040]
    uint8 constant AUDIO_CN 	 	  = 19; // [RFC3389]
    uint8 constant AUDIO_DAT12 	      = 20; // [RFC3190]
    uint8 constant AUDIO_dls 	 	  = 21; // [RFC4613]
    uint8 constant AUDIO_dsr_es201108 = 22; // [RFC3557]
    uint8 constant AUDIO_dsr_es202050 = 23; // [RFC4060]
    uint8 constant AUDIO_dsr_es202211 = 24; // [RFC4060]
    uint8 constant AUDIO_dsr_es202212 = 25; // [RFC4060]
    uint8 constant AUDIO_DV 	      = 26; // [RFC6469]
    uint8 constant AUDIO_DVI4 	 	  = 27; // [RFC4856]
    uint8 constant AUDIO_eac3 	 	  = 28; // [RFC4598]
    uint8 constant AUDIO_encaprtp     = 29; // [RFC6849]
    uint8 constant AUDIO_EVRC 	      = 30; // [RFC4788]
    uint8 constant AUDIO_EVRC_QCP     = 31; // [RFC3625]
    uint8 constant AUDIO_EVRC0 		  = 32; // [RFC4788]
    uint8 constant AUDIO_EVRC1 		  = 33; // [RFC4788]
    uint8 constant AUDIO_EVRCB 		  = 34; // [RFC5188]
    uint8 constant AUDIO_EVRCB0 	  = 35; // [RFC5188]
    uint8 constant AUDIO_EVRCB1 	  = 36; // [RFC4788]
    uint8 constant AUDIO_EVRCNW 	  = 37; // [RFC6884]
    uint8 constant AUDIO_EVRCNW0 	  = 38; // [RFC6884]
    uint8 constant AUDIO_EVRCNW1 	  = 39; // [RFC6884]
    uint8 constant AUDIO_EVRCWB 	  = 40; // [RFC5188]
    uint8 constant AUDIO_EVRCWB0 	  = 41; // [RFC5188]
    uint8 constant AUDIO_EVRCWB1 	  = 42; // [RFC5188]
    uint8 constant AUDIO_EVS 	 	  = 43; // [_3GPP][Kyunghun_Jung]
    uint8 constant AUDIO_example 	  = 44; // [RFC4735]
    uint8 constant AUDIO_flexfec 	  = 45; // [RFC8627]
    uint8 constant AUDIO_fwdred 	  = 46; // [RFC6354]
    uint8 constant AUDIO_G711_0 	  = 47; // [RFC7655]
    uint8 constant AUDIO_G719 	      = 48; // [RFC5404][RFC Errata 3245]
    uint8 constant AUDIO_G7221 		  = 49; // [RFC5577]
    uint8 constant AUDIO_G722 	      = 50; // [RFC4856]
    uint8 constant AUDIO_G723 	      = 51; // [RFC4856]
    uint8 constant AUDIO_G726_16 	  = 52; // [RFC4856]
    uint8 constant AUDIO_G726_24 	  = 53; // [RFC4856]
    uint8 constant AUDIO_G726_32 	  = 54; // [RFC4856]
    uint8 constant AUDIO_G726_40 	  = 55; // [RFC4856]
    uint8 constant AUDIO_G728 	      = 56; // [RFC4856]
    uint8 constant AUDIO_G729 	      = 57; // [RFC4856]
    uint8 constant AUDIO_G7291 		  = 58; // [RFC4749][RFC5459]
    uint8 constant AUDIO_G729D 		  = 59; // [RFC4856]
    uint8 constant AUDIO_G729E 		  = 60; // [RFC4856]
    uint8 constant AUDIO_GSM 	      = 61; // [RFC4856]
    uint8 constant AUDIO_GSM_EFR 	  = 62; // [RFC4856]
    uint8 constant AUDIO_GSM_HR_08 	  = 63; // [RFC5993]
    uint8 constant AUDIO_iLBC 	      = 64; // [RFC3952]
    uint8 constant AUDIO_ip_mr_v2_5   = 65; // [RFC6262]
    uint8 constant AUDIO_L8 	      = 66; // [RFC4856]
    uint8 constant AUDIO_L16 		  = 67; // [RFC4856]
    uint8 constant AUDIO_L20 		  = 68; // [RFC3190]
    uint8 constant AUDIO_L24 		  = 69; // [RFC3190]
    uint8 constant AUDIO_LPC 		  = 70; // [RFC4856]
    uint8 constant AUDIO_MELP 	      = 71; // [RFC8130]
    uint8 constant AUDIO_MELP600 	  = 72; // [RFC8130]
    uint8 constant AUDIO_MELP1200  	  = 73; // [RFC8130]
    uint8 constant AUDIO_MELP2400  	  = 74; // [RFC8130]
    uint8 constant AUDIO_mhas 	      = 75; // [ISO-IEC_JTC1][Nils_Peters][Ingo_Hofmann]
    uint8 constant AUDIO_mobile_xmf   = 76; // [RFC4723]
    uint8 constant AUDIO_MPA 		  = 77; // [RFC3555]
    uint8 constant AUDIO_mp4 	      = 78; // [RFC4337][RFC6381]
    uint8 constant AUDIO_MP4A_LATM 	  = 79; // [RFC6416]
    uint8 constant AUDIO_mpa_robust   = 80; // [RFC5219]
    uint8 constant AUDIO_mpeg 	      = 81; // [RFC3003]
    uint8 constant AUDIO_mpeg4_generic = 82; // [RFC3640][RFC5691][RFC6295]
    uint8 constant AUDIO_ogg 	      = 83; // [RFC5334][RFC7845]
    uint8 constant AUDIO_opus 	 	  = 84; // [RFC7587]
    uint8 constant AUDIO_parityfec 	  = 85; // [RFC3009]
    uint8 constant AUDIO_PCMA 	 	  = 86; // [RFC4856]
    uint8 constant AUDIO_PCMA_WB 	  = 87; // [RFC5391]
    uint8 constant AUDIO_PCMU 	 	  = 88; // [RFC4856]
    uint8 constant AUDIO_PCMU_WB 	  = 89; // [RFC5391]
    uint8 constant AUDIO_prs_sid 	  = 90; // [Linus_Walleij]
    uint8 constant AUDIO_QCELP 	      = 91; // [RFC3555][RFC3625]
    uint8 constant AUDIO_raptorfec 	  = 92; // [RFC6682]
    uint8 constant AUDIO_RED 	      = 93; // [RFC3555]
    uint8 constant AUDIO_rtp_enc_aescm128 = 94; // [_3GPP]
    uint8 constant AUDIO_rtploopback  = 95; // [RFC6849]
    uint8 constant AUDIO_rtp_midi 	  = 96; // [RFC6295]
    uint8 constant AUDIO_rtx 	      = 97; // [RFC4588]
    uint8 constant AUDIO_scip 	      = 98; // [SCIP][Michael_Faller][Daniel_Hanson]
    uint8 constant AUDIO_SMV 	      = 99; // [RFC3558]
    uint8 constant AUDIO_SMV0 	 	  = 100; // [RFC3558]
    uint8 constant AUDIO_SMV_QCP 	  = 101; // [RFC3625]
    uint8 constant AUDIO_sofa 	 	  = 102; // [AES][Piotr_Majdak]
    uint8 constant AUDIO_sp_midi 	  = 103; // [Timo_Kosonen][Tom_White]
    uint8 constant AUDIO_speex 	 	  = 104; // [RFC5574]
    uint8 constant AUDIO_t140c 	 	  = 105; // [RFC4351]
    uint8 constant AUDIO_t38 	      = 106; // [RFC4612]
    uint8 constant AUDIO_telephone_event = 107; // [RFC4733]
    uint8 constant AUDIO_TETRA_ACELP  = 108; // [ETSI][Miguel_Angel_Reina_Ortega]
    uint8 constant AUDIO_TETRA_ACELP_BB = 109; // [ETSI][Miguel_Angel_Reina_Ortega]
    uint8 constant AUDIO_tone 	      = 110; // [RFC4733]
    uint8 constant AUDIO_TSVCIS 	  = 111; // [RFC8817]
    uint8 constant AUDIO_UEMCLIP 	  = 112; // [RFC5686]
    uint8 constant AUDIO_ulpfec 	  = 113; // [RFC5109]
    uint8 constant AUDIO_usac 	      = 114; // [ISO-IEC_JTC1][Max_Neuendorf]
    uint8 constant AUDIO_VDVI 	      = 115; // [RFC4856]
    uint8 constant AUDIO_VMR_WB 	  = 116; // [RFC4348][RFC4424]
    uint8 constant AUDIO_vnd_3gpp_iufp = 117; // [Thomas_Belling]
    uint8 constant AUDIO_vnd_4SB 	  = 118; // [Serge_De_Jaham]
    uint8 constant AUDIO_vnd_audiokoz = 119; // [Vicki_DeBarros]
    uint8 constant AUDIO_vnd_CELP 	  = 120; // [Serge_De_Jaham]
    uint8 constant AUDIO_vnd_cisco_nse = 121; // [Rajesh_Kumar]
    uint8 constant AUDIO_vnd_cmles_radio_events = 122; // [Jean-Philippe_Goulet]
    uint8 constant AUDIO_vnd_cns_anp1 	  = 123; // [Ann_McLaughlin]
    uint8 constant AUDIO_vnd_cns_inf1 	  = 124; // [Ann_McLaughlin]
    uint8 constant AUDIO_vnd_dece_audio   = 125; // [Michael_A_Dolan]
    uint8 constant AUDIO_vnd_digital_winds = 126; // [Armands_Strazds]
    uint8 constant AUDIO_vnd_dlna_adts 	  = 127; // [Edwin_Heredia]
    uint8 constant AUDIO_vnd_dolby_heaac_1 = 128; // [Steve_Hattersley]
    uint8 constant AUDIO_vnd_dolby_heaac_2 = 129; // [Steve_Hattersley]
    uint8 constant AUDIO_vnd_dolby_mlp 	   = 130; // [Mike_Ward]
    uint8 constant AUDIO_vnd_dolby_mps 	   = 131; // [Steve_Hattersley]
    uint8 constant AUDIO_vnd_dolby_pl2 	   = 132; // [Steve_Hattersley]
    uint8 constant AUDIO_vnd_dolby_pl2x    = 133; // [Steve_Hattersley]
    uint8 constant AUDIO_vnd_dolby_pl2z    = 134; // [Steve_Hattersley]
    uint8 constant AUDIO_vnd_dolby_pulse_1 = 135; // [Steve_Hattersley]
    uint8 constant AUDIO_vnd_dra  	       = 136; // [Jiang_Tian]
    uint8 constant AUDIO_vnd_dts 	       = 137; // [William_Zou]
    uint8 constant AUDIO_vnd_dts_hd 	   = 138; // [William_Zou]
    uint8 constant AUDIO_vnd_dts_uhd 	   = 139; // [Phillip_Maness]
    uint8 constant AUDIO_vnd_dvb_file 	   = 140; // [Peter_Siebert]
    uint8 constant AUDIO_vnd_everad_plj    = 141; // [Shay_Cicelsky]
    uint8 constant AUDIO_vnd_hns_audio 	   = 142; // [Swaminathan]
    uint8 constant AUDIO_vnd_lucent_voice  = 143; // [Greg_Vaudreuil]
    uint8 constant AUDIO_vnd_ms_playready_media_pya = 144; // [Steve_DiAcetis]
    uint8 constant AUDIO_vnd_nokia_mobile_xmf = 145; // [Nokia]
    uint8 constant AUDIO_vnd_nortel_vbk 	  = 146; // [Glenn_Parsons]
    uint8 constant AUDIO_vnd_nuera_ecelp4800  = 147; // [Michael_Fox]
    uint8 constant AUDIO_vnd_nuera_ecelp7470  = 148; // [Michael_Fox]
    uint8 constant AUDIO_vnd_nuera_ecelp9600  = 149; // [Michael_Fox]
    uint8 constant AUDIO_vnd_octel_sbc 	      = 150; // [Greg_Vaudreuil]
    uint8 constant AUDIO_vnd_presonus_multitrack = 151; // [Matthias_Juwan]
    uint8 constant AUDIO_vnd_qcelp            = 152; // [RFC3625]- DEPRECATED in favor of audio/qcelp
    uint8 constant AUDIO_vnd_rhetorex_32kadpcm = 153; // [Greg_Vaudreuil]
    uint8 constant AUDIO_vnd_rip 	 	      = 154; // [Martin_Dawe]
    uint8 constant AUDIO_vnd_sealedmedia_softseal_mpeg = 155; // [David_Petersen]
    uint8 constant AUDIO_vnd_vmx_cvsd 	 	  = 156; // [Greg_Vaudreuil]
    uint8 constant AUDIO_vorbis 	 	      = 157; // [RFC5215]
    uint8 constant AUDIO_vorbis_config 	 	  = 158; // [RFC5215]

    function mime_subtype_string(uint type_id, uint subtype_id) internal returns (string) {
        if (type_id == AUDIO) {
            if (subtype_id == AUDIO_1d_interleaved_parityfec) return "1d_interleaved_parityfec";
            if (subtype_id == AUDIO_32kadpcm) return "32kadpcm";
            if (subtype_id == AUDIO_3gpp) return "3gpp";
            if (subtype_id == AUDIO_3gpp2) return "3gpp2";
            if (subtype_id == AUDIO_aac) return "aac";
            if (subtype_id == AUDIO_ac3) return "ac3";
            if (subtype_id == AUDIO_AMR) return "AMR";
            if (subtype_id == AUDIO_AMR_WB) return "AMR_WB";
            if (subtype_id == AUDIO_amr_wb_plus) return "amr_wb_plus";
            if (subtype_id == AUDIO_aptx) return "aptx";
            if (subtype_id == AUDIO_asc) return "asc";
            if (subtype_id == AUDIO_ATRAC_ADVANCED_LOSSLESS) return "ATRAC_ADVANCED_LOSSLESS";
            if (subtype_id == AUDIO_ATRAC_X) return "ATRAC_X";
            if (subtype_id == AUDIO_ATRAC3) return "ATRAC3";
            if (subtype_id == AUDIO_basic) return "basic";
            if (subtype_id == AUDIO_BV16) return "BV16";
            if (subtype_id == AUDIO_BV32) return "BV32";
            if (subtype_id == AUDIO_clearmode) return "clearmode";
            if (subtype_id == AUDIO_CN) return "CN";
            if (subtype_id == AUDIO_DAT12) return "DAT12";
            if (subtype_id == AUDIO_dls) return "dls";
            if (subtype_id == AUDIO_dsr_es201108) return "dsr_es201108";
            if (subtype_id == AUDIO_dsr_es202050) return "dsr_es202050";
            if (subtype_id == AUDIO_dsr_es202211) return "dsr_es202211";
            if (subtype_id == AUDIO_dsr_es202212) return "dsr_es202212";
            if (subtype_id == AUDIO_DV) return "DV";
            if (subtype_id == AUDIO_DVI4) return "DVI4";
            if (subtype_id == AUDIO_eac3) return "eac3";
            if (subtype_id == AUDIO_encaprtp) return "encaprtp";
            if (subtype_id == AUDIO_EVRC) return "EVRC";
            if (subtype_id == AUDIO_EVRC_QCP) return "EVRC_QCP";
            if (subtype_id == AUDIO_EVRC0) return "EVRC0";
            if (subtype_id == AUDIO_EVRC1) return "EVRC1";
            if (subtype_id == AUDIO_EVRCB) return "EVRCB";
            if (subtype_id == AUDIO_EVRCB0) return "EVRCB0";
            if (subtype_id == AUDIO_EVRCB1) return "EVRCB1";
            if (subtype_id == AUDIO_EVRCNW) return "EVRCNW";
            if (subtype_id == AUDIO_EVRCNW0) return "EVRCNW0";
            if (subtype_id == AUDIO_EVRCNW1) return "EVRCNW1";
            if (subtype_id == AUDIO_EVRCWB) return "EVRCWB";
            if (subtype_id == AUDIO_EVRCWB0) return "EVRCWB0";
            if (subtype_id == AUDIO_EVRCWB1) return "EVRCWB1";
            if (subtype_id == AUDIO_EVS) return "EVS";
            if (subtype_id == AUDIO_example) return "example";
            if (subtype_id == AUDIO_flexfec) return "flexfec";
            if (subtype_id == AUDIO_fwdred) return "fwdred";
            if (subtype_id == AUDIO_G711_0) return "G711_0";
            if (subtype_id == AUDIO_G719) return "G719";
            if (subtype_id == AUDIO_G7221) return "G7221";
            if (subtype_id == AUDIO_G722) return "G722";
            if (subtype_id == AUDIO_G723) return "G723";
            if (subtype_id == AUDIO_G726_16) return "G726_16";
            if (subtype_id == AUDIO_G726_24) return "G726_24";
            if (subtype_id == AUDIO_G726_32) return "G726_32";
            if (subtype_id == AUDIO_G726_40) return "G726_40";
            if (subtype_id == AUDIO_G728) return "G728";
            if (subtype_id == AUDIO_G729) return "G729";
            if (subtype_id == AUDIO_G7291) return "G7291";
            if (subtype_id == AUDIO_G729D) return "G729D";
            if (subtype_id == AUDIO_G729E) return "G729E";
            if (subtype_id == AUDIO_GSM) return "GSM";
            if (subtype_id == AUDIO_GSM_EFR) return "GSM_EFR";
            if (subtype_id == AUDIO_GSM_HR_08) return "GSM_HR_08";
            if (subtype_id == AUDIO_iLBC) return "iLBC";
            if (subtype_id == AUDIO_ip_mr_v2_5) return "ip_mr_v2_5";
            if (subtype_id == AUDIO_L8) return "L8";
            if (subtype_id == AUDIO_L16) return "L16";
            if (subtype_id == AUDIO_L20) return "L20";
            if (subtype_id == AUDIO_L24) return "L24";
            if (subtype_id == AUDIO_LPC) return "LPC";
            if (subtype_id == AUDIO_MELP) return "MELP";
            if (subtype_id == AUDIO_MELP600) return "MELP600";
            if (subtype_id == AUDIO_MELP1200) return "MELP1200";
            if (subtype_id == AUDIO_MELP2400) return "MELP2400";
            if (subtype_id == AUDIO_mhas) return "mhas";
            if (subtype_id == AUDIO_mobile_xmf) return "mobile_xmf";
            if (subtype_id == AUDIO_MPA) return "MPA";
            if (subtype_id == AUDIO_mp4) return "mp4";
            if (subtype_id == AUDIO_MP4A_LATM) return "MP4A_LATM";
            if (subtype_id == AUDIO_mpa_robust) return "mpa_robust";
            if (subtype_id == AUDIO_mpeg) return "mpeg";
            if (subtype_id == AUDIO_mpeg4_generic) return "mpeg4_generic";
            if (subtype_id == AUDIO_ogg) return "ogg";
            if (subtype_id == AUDIO_opus) return "opus";
            if (subtype_id == AUDIO_parityfec) return "parityfec";
            if (subtype_id == AUDIO_PCMA) return "PCMA";
            if (subtype_id == AUDIO_PCMA_WB) return "PCMA_WB";
            if (subtype_id == AUDIO_PCMU) return "PCMU";
            if (subtype_id == AUDIO_PCMU_WB) return "PCMU_WB";
            if (subtype_id == AUDIO_prs_sid) return "prs_sid";
            if (subtype_id == AUDIO_QCELP) return "QCELP";
            if (subtype_id == AUDIO_raptorfec) return "raptorfec";
            if (subtype_id == AUDIO_RED) return "RED";
            if (subtype_id == AUDIO_rtp_enc_aescm128) return "rtp_enc_aescm128";
            if (subtype_id == AUDIO_rtploopback) return "rtploopback";
            if (subtype_id == AUDIO_rtp_midi) return "rtp_midi";
            if (subtype_id == AUDIO_rtx) return "rtx";
            if (subtype_id == AUDIO_scip) return "scip";
            if (subtype_id == AUDIO_SMV) return "SMV";
            if (subtype_id == AUDIO_SMV0) return "SMV0";
            if (subtype_id == AUDIO_SMV_QCP) return "SMV_QCP";
            if (subtype_id == AUDIO_sofa) return "sofa";
            if (subtype_id == AUDIO_sp_midi) return "sp_midi";
            if (subtype_id == AUDIO_speex) return "speex";
            if (subtype_id == AUDIO_t140c) return "t140c";
            if (subtype_id == AUDIO_t38) return "t38";
            if (subtype_id == AUDIO_telephone_event) return "telephone_event";
            if (subtype_id == AUDIO_TETRA_ACELP) return "TETRA_ACELP";
            if (subtype_id == AUDIO_TETRA_ACELP_BB) return "TETRA_ACELP_BB";
            if (subtype_id == AUDIO_tone) return "tone";
            if (subtype_id == AUDIO_TSVCIS) return "TSVCIS";
            if (subtype_id == AUDIO_UEMCLIP) return "UEMCLIP";
            if (subtype_id == AUDIO_ulpfec) return "ulpfec";
            if (subtype_id == AUDIO_usac) return "usac";
            if (subtype_id == AUDIO_VDVI) return "VDVI";
            if (subtype_id == AUDIO_VMR_WB) return "VMR_WB";
            if (subtype_id == AUDIO_vnd_3gpp_iufp) return "vnd_3gpp_iufp";
            if (subtype_id == AUDIO_vnd_4SB) return "vnd_4SB";
            if (subtype_id == AUDIO_vnd_audiokoz) return "vnd_audiokoz";
            if (subtype_id == AUDIO_vnd_CELP) return "vnd_CELP";
            if (subtype_id == AUDIO_vnd_cisco_nse) return "vnd_cisco_nse";
            if (subtype_id == AUDIO_vnd_cmles_radio_events) return "vnd_cmles_radio_events";
            if (subtype_id == AUDIO_vnd_cns_anp1) return "vnd_cns_anp1";
            if (subtype_id == AUDIO_vnd_cns_inf1) return "vnd_cns_inf1";
            if (subtype_id == AUDIO_vnd_dece_audio) return "vnd_dece_audio";
            if (subtype_id == AUDIO_vnd_digital_winds) return "vnd_digital_winds";
            if (subtype_id == AUDIO_vnd_dlna_adts) return "vnd_dlna_adts";
            if (subtype_id == AUDIO_vnd_dolby_heaac_1) return "vnd_dolby_heaac_1";
            if (subtype_id == AUDIO_vnd_dolby_heaac_2) return "vnd_dolby_heaac_2";
            if (subtype_id == AUDIO_vnd_dolby_mlp) return "vnd_dolby_mlp";
            if (subtype_id == AUDIO_vnd_dolby_mps) return "vnd_dolby_mps";
            if (subtype_id == AUDIO_vnd_dolby_pl2) return "vnd_dolby_pl2";
            if (subtype_id == AUDIO_vnd_dolby_pl2x) return "vnd_dolby_pl2x";
            if (subtype_id == AUDIO_vnd_dolby_pl2z) return "vnd_dolby_pl2z";
            if (subtype_id == AUDIO_vnd_dolby_pulse_1) return "vnd_dolby_pulse_1";
            if (subtype_id == AUDIO_vnd_dra) return "vnd_dra";
            if (subtype_id == AUDIO_vnd_dts) return "vnd_dts";
            if (subtype_id == AUDIO_vnd_dts_hd) return "vnd_dts_hd";
            if (subtype_id == AUDIO_vnd_dts_uhd) return "vnd_dts_uhd";
            if (subtype_id == AUDIO_vnd_dvb_file) return "vnd_dvb_file";
            if (subtype_id == AUDIO_vnd_everad_plj) return "vnd_everad_plj";
            if (subtype_id == AUDIO_vnd_hns_audio) return "vnd_hns_audio";
            if (subtype_id == AUDIO_vnd_lucent_voice) return "vnd_lucent_voice";
            if (subtype_id == AUDIO_vnd_ms_playready_media_pya) return "vnd_ms_playready_media_pya";
            if (subtype_id == AUDIO_vnd_nokia_mobile_xmf) return "vnd_nokia_mobile_xmf";
            if (subtype_id == AUDIO_vnd_nortel_vbk) return "vnd_nortel_vbk";
            if (subtype_id == AUDIO_vnd_nuera_ecelp4800) return "vnd_nuera_ecelp4800";
            if (subtype_id == AUDIO_vnd_nuera_ecelp7470) return "vnd_nuera_ecelp7470";
            if (subtype_id == AUDIO_vnd_nuera_ecelp9600) return "vnd_nuera_ecelp9600";
            if (subtype_id == AUDIO_vnd_octel_sbc) return "vnd_octel_sbc";
            if (subtype_id == AUDIO_vnd_presonus_multitrack) return "vnd_presonus_multitrack";
            if (subtype_id == AUDIO_vnd_qcelp) return "vnd_qcelp";
            if (subtype_id == AUDIO_vnd_rhetorex_32kadpcm) return "vnd_rhetorex_32kadpcm";
            if (subtype_id == AUDIO_vnd_rip) return "vnd_rip";
            if (subtype_id == AUDIO_vnd_sealedmedia_softseal_mpeg) return "vnd_sealedmedia_softseal_mpeg";
            if (subtype_id == AUDIO_vnd_vmx_cvsd) return "vnd_vmx_cvsd";
            if (subtype_id == AUDIO_vorbis) return "vorbis";
            if (subtype_id == AUDIO_vorbis_config) return "vorbis_config";
        }
    }
}