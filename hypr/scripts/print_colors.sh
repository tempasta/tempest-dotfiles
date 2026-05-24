while read -r color; do
    hex="${color#"#"}"

    r=$((16#${hex:0:2}))
    g=$((16#${hex:2:2}))
    b=$((16#${hex:4:2}))

    printf "\e[48;2;%s;%s;%sm   \e[0m %-10s (%s)\n" \
        "$r" "$g" "$b" "$color" "color$i"

    ((i++))
done < ~/.cache/wal/colors
