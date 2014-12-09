 #!/bin/bash

# Take 3 images from an affiliate directory, concatenate them and create a single image that 
# contains all 3 source images. 


offers=$(ls /Users/alan/va/site/test/www/include/partners/);
site=veteransadvantage

#for partner in ${offers[@]}; do
#	echo "Capturing pages for partner $partner"
#	osascript /Users/alan/Documents/webcap.scpt $partner $site
#done

cd /Users/alan/Desktop/partners/veteransadvantage

for partner in ${offers[@]}; do
    jpegtopnm ${partner}_1.jpeg > ${partner}_1.pnm
    jpegtopnm ${partner}_2.jpeg > ${partner}_2.pnm
    jpegtopnm ${partner}_3.jpeg > ${partner}_3.pnm
    
    pnmcat --topbottom \
           ${partner}_1.pnm ${partner}_2.pnm ${partner}_3.pnm \
    | pnmtojpeg -quality=50 -optimize > ${partner}.jpeg

    rm ${partner}_{1,2,3}.pnm

done

