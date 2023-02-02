all: openjtalk/open_jtalk_dic_utf_8-1.11 openjtalk/hts_voice_nitech_jp_atr503_m001-1.05 openjtalk/openjtalk.js

openjtalk/.marker:
	mkdir -p openjtalk
	touch openjtalk/.marker

openjtalk/open_jtalk_dic_utf_8-1.11: openjtalk/.marker
	curl https://jaist.dl.sourceforge.net/project/open-jtalk/Dictionary/open_jtalk_dic-1.11/open_jtalk_dic_utf_8-1.11.tar.gz -o openjtalk/open_jtalk_dic_utf_8-1.11.tar.gz
	tar -xvf openjtalk/open_jtalk_dic_utf_8-1.11.tar.gz -C openjtalk

openjtalk/hts_voice_nitech_jp_atr503_m001-1.05: openjtalk/.marker
	curl https://jaist.dl.sourceforge.net/project/open-jtalk/HTS%20voice/hts_voice_nitech_jp_atr503_m001-1.05/hts_voice_nitech_jp_atr503_m001-1.05.tar.gz -o openjtalk/hts_voice_nitech_jp_atr503_m001-1.05.tar.gz
	tar -xvf openjtalk/hts_voice_nitech_jp_atr503_m001-1.05.tar.gz -C openjtalk

openjtalk/openjtalk.js: openjtalk/.marker
	if [ -d openjtalk/openjtalk-wasm ]; then \
		rm -rf openjtalk/openjtalk-wasm; \
	fi
	git clone https://github.com/KoharuYuzuki/openjtalk-wasm.git openjtalk/openjtalk-wasm
	cd openjtalk/openjtalk-wasm && \
		git apply ../../openjtalk-wasm-build.patch --ignore-whitespace && \
	 	./build.sh && \
		cp -f ./build/openjtalk.* ../../openjtalk

