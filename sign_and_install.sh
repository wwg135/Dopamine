set -e

zsign -k ./.sign/pkey.p12 -p 1234 -m ./.sign/development.cer -b $1 -m ./.sign/profile.mobileprovision -o ./.sign/Dopamine.signed.ipa ./Application/Dopamine.ipa
ideviceinstaller install ./.sign/Dopamine.signed.ipa