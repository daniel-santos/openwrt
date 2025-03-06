
ifneq ($(filter DEVICE_myir%,$(call qstrip,$(CONFIG_TARGET_PROFILE))),)
 define Package/base-files/install-target
	echo "======================#=#=#=#=#=#=#=#=#=#="
	$(foreach v, \
		$(shell echo "$(filter-out .VARIABLES,$(.VARIABLES))" | tr ' ' '\n' | sort), \
		$(info /tmp/make_vars,$(shell printf "%-20s" "$(v)")= $(value $(v))) \
	)
	$(foreach d,$(foreach subdir,mcg-beyond,$(PLATFORM_SUBDIR)/$(subdir)),\
		if [ -d $(d) ] && ls -d $(d)/* > /dev/null ; then \
			$(CP) $(d)/* $(1)/; \
		fi; \
	)
 endef
endif
