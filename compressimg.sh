#Run this in the directory of the pngs you want to crush
for file in *.png; do pngcrush -fix -c 6 -rem alla -force "$file" "$file-crushed" && mv "$file-crushed" "$file"; done
