PICS = \
	if-transformer.jpg \
	vintage-mixer.webp \
	vintage-superhet.webp \
	am-modulation.svg

presentation.html:	slides.md mermaid.lua mermaid-config.json mermaid-sync.html $(PICS)
	pandoc -t revealjs -s $< -o $@ \
		--mathml \
		--lua-filter=mermaid.lua \
		-H mermaid-sync.html \
		--embed-resources

.PHONY: clean

clean:
	rm -f presentation.html
