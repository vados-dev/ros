#!rsc by Vados
# RouterOS script: mod/AM-IPcalc
# Script comment: ip address calculation
#
#
# requires RouterOS, version=7.19

:local IPCalc;

# print netmask, network, min host, max host and broadcast
:set IPCalc do={ :onerror Err {
  :local Input [ :tostr $1 ];
  :local FormatLine;
  :local IPCalcReturn;
  :local Values [ $IPCalcReturn $1 ];
  :set FormatLine do={
    :local Key    [ :tostr $1 ];
    :local Value  [ :tostr $2 ];
    :local Indent [ :tonum $3 ];
    :local Spaces;
    :local Return "";
    :local CharacterMultiply;
    :local EitherOr;
    :set CharacterMultiply do={
      :local Str [ :tostr $1 ];
      :local Num [ :tonum $2 ];
      :local Return "";
      :if ($Num = 0) do={:return ""}
      :for I from=1 to=$Num do={:set Return ($Return . $Str)}
      :return $Return;
    }
    :set EitherOr do={
      :local IfThenElse;
      :set IfThenElse do={:if ([ :tostr $1 ] = "true" || [ :tobool $1 ] = true) do={ :return $2 }; :return $3; }
      :if ([ :typeof $1 ] = "num") do={:return [ $IfThenElse ($1 != 0) $1 $2 ]}
      :if ([ :typeof $1 ] = "time") do={:return [ $IfThenElse ($1 > 0s) $1 $2 ]}
      :return [ $IfThenElse ([ :len [ :tostr $1 ] ] > 0) $1 $2 ];
    }
    :set Indent [ $EitherOr $Indent 16 ];
    :local Spaces [ $CharacterMultiply " " $Indent ];
    :if ([ :len $Key ] > 0) do={ :set Return ($Key . ":")}
    :if ([ :len $Key ] > ($Indent - 2)) do={:set Return ($Return . "\n" . [ :pick $Spaces 0 $Indent ] . $Value);
    } else={:set Return ($Return . [ :pick $Spaces 0 ($Indent - [ :len $Return ]) ] . $Value)}
    :return $Return;
  }
  :put [ :tocrlf ( \
    [ $FormatLine "Address" ($Values->"address") ] . "\n" . \
    [ $FormatLine "Netmask" ($Values->"netmask") ] . "\n" . \
    [ $FormatLine "Network" ($Values->"network") ] . "\n" . \
    [ $FormatLine "HostMin" ($Values->"hostmin") ] . "\n" . \
    [ $FormatLine "HostMax" ($Values->"hostmax") ] . "\n" . \
    [ $FormatLine "Broadcast" ($Values->"broadcast") ]) ];
} do={
  :log error ("Error:" );
} }

# calculate and return netmask, network, min host, max host and broadcast
:set IPCalcReturn do={
  :local Input [ :tostr $1 ];
  :global NetMask4;
  :global NetMask6;
  :local Address [ :pick $Input 0 [ :find $Input "/" ] ];
  :local Bits [ :tonum [ :pick $Input ([ :find $Input "/" ] + 1) [ :len $Input ] ] ];
  :local Mask;
  :local One;
  :if ([ :typeof [ :toip $Address ] ] = "ip") do={
    :set Address [ :toip $Address ];
    :set Mask [ $NetMask4 $Bits ];
    :set One 0.0.0.1;
  } else={
    :set Address [ :toip6 $Address ];
    :set Mask [ $NetMask6 $Bits ];
    :set One ::1;
  }
  :local Return ({
    "address"=$Address;
    "netmask"=$Mask;
    "networkaddress"=($Address & $Mask);
    "networkbits"=$Bits;
    "network"=(($Address & $Mask) . "/" . $Bits);
    "hostmin"=(($Address & $Mask) | $One);
    "hostmax"=(($Address | ~$Mask) ^ $One);
    "broadcast"=($Address | ~$Mask);
  });
  :return $Return;
}
