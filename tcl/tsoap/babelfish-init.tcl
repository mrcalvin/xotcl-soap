SOAP::configure -transport http -proxy {}

SOAP::create translate \
    -proxy {http://services.xmethods.net:80/perl/soaplite.cgi} \
    -uri "urn:xmethodsBabelFish\#BabelFish" \
    -params { translationmode string sourcedata string }

# example:
# set english [translate de_en "Hallo Welt, Guten Tag"]
