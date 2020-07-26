#!/bin/bash

control_file=$(cat)
pkg=$(echo "${control_file}" | grep -E '^Package:' | perl -pe 's|^Package: ||g;')
echo "define Package/${pkg}"

deps=$(echo "${control_file}" |
    grep -E '^Depends: ' |
    perl -pe '
	s|^Depends: |+|g;
	s|,\s+| +|g;
    '
)

echo "${control_file}" |
grep -E '^\w+:' |
perl -pe "
    s|^Section:|	SECTION\t\t:=|g;
    s|^Depends:.*$|	DEPENDS\t\t:= ${deps}|g;
    s|^Provides:|	PROVIDES\t:=|g;
    s|^Maintainer:|	MAINTAINER\t:=|g;
    s|^Source:|	SOURCE\t\t:=|g;
    s|^Version:|	VERSION\t\t:=|g;
    s|^Architecture:|	PKGARCH\t\t:=|g;
    s|^Alternatives:|	ALTERNATIVES\t\t:=|g;
    s|^License:|	LICENSE\t\t:=|g;
    s|^LicenseFiles:|	LICENSE_FILES\t:=|g;
" | grep -E '^\s\w+\s+:='
echo "endef"
echo
echo "define Package/${pkg}/description"
echo "${control_file}" | grep -E 'Description: ' | perl -pe 's|Description: ||g;'
echo "${control_file}" | grep -vE '\w+: '
echo "endef"

