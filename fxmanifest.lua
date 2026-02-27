author "Dusk & Ludwig"
description "Ped Manager for RedM using ox_lib Points"
version "1.0.0"

fx_version "cerulean"
rdr3_warning "I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships."

game "rdr3"
lua54 "yes"

dependencies {
    'ox_lib',
   -- 'murphy_interact', -- falls man mit Interact arbeiten will kann man direkt anbinden.
}

shared_scripts {
    '@ox_lib/init.lua',
}

client_scripts {
    'client/client.lua',
}
