function flags=CFF_get_R7012_flags(flag_dec)

if isnumeric(flag_dec)
    flag_bin = dec2bin(flag_dec, 16);
else
    flag_bin = flag_dec;
end

flags.pitchStab = 0;
flags.rollStab  = 0;
flags.yawStab   = 0;
flags.heaveStab = 0;

flags.pitchStab = bin2dec(flag_bin(16-0));
flags.rollStab  = bin2dec(flag_bin(16-1));
flags.yawStab   = bin2dec(flag_bin(16-2));
flags.heaveStab = bin2dec(flag_bin(16-3));





