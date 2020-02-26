if [ x$1 = x ]; then
  echo "REMEMBER RLEEASE ID"
fi
mkdir vxtron32
cp vltron.bas vxtron32/vxtron32.bas
sed -i "s/GIT MASTER/$*/g" vxtron32/vxtron32.bas
cp vxtron.ayc vxtron32/
cp README.md vxtron32/
zip -r vxtron32.zip vxtron32
