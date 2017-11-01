function db=pow2db_perso(pow)

    pow(pow<0)=nan;
    db=10*log10(pow);

end