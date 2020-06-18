if [ "x$1" = "x" ]; then
  echo "REMEMBER RLEEASE ID"
fi
rm -rf vxtron32
rm vxtron32.zip
mkdir vxtron32
python ../objtools/vx32-bundle.py vltron.bas vxtron32/vxtron32.bas      
sed -i "s/GIT MASTER/$*/g" vxtron32/vxtron32.bas
cp vxtron.jjay vxtron32/
cp *.vsfx vxtron32/ 
cp *.o32 vxtron32/
cp *.s32 vxtron32/
cp README.md vxtron32/
zip -r vxtron32.zip vxtron32
