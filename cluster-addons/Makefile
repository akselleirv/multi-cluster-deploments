gen:
	cd deployments && cue cmd gen
	find charts/*/generated_values/ -type f -delete &2>/dev/null
	cd clusters && cue cmd gen
