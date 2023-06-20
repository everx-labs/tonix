while true
do
    read -p "$ " input
    case $input in
        q|quit) break;;
        *) make run c="$input";;
    esac
done
