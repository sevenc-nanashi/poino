all: openjtalk/open_jtalk_dic_utf_8-1.11 openjtalk/hts_voice_nitech_jp_atr503_m001-1.05

openjtalk:
	mkdir -p openjtalk

openjtalk/open_jtalk_dic_utf_8-1.11: openjtalk
	curl https://jaist.dl.sourceforge.net/project/open-jtalk/Dictionary/open_jtalk_dic-1.11/open_jtalk_dic_utf_8-1.11.tar.gz -o openjtalk/open_jtalk_dic_utf_8-1.11.tar.gz
	tar -xvf openjtalk/open_jtalk_dic_utf_8-1.11.tar.gz -C openjtalk

openjtalk/hts_voice_nitech_jp_atr503_m001-1.05: openjtalk
	curl https://jaist.dl.sourceforge.net/project/open-jtalk/HTS%20voice/hts_voice_nitech_jp_atr503_m001-1.05/hts_voice_nitech_jp_atr503_m001-1.05.tar.gz -o openjtalk/hts_voice_nitech_jp_atr503_m001-1.05.tar.gz
	tar -xvf openjtalk/hts_voice_nitech_jp_atr503_m001-1.05.tar.gz -C openjtalk
