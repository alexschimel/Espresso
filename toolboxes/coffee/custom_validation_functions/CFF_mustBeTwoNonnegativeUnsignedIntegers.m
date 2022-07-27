function CFF_mustBeTwoNonnegativeUnsignedIntegers(a)
    if ~(isvector(a) && numel(a)==2 && isreal(a) && isnumeric(a) && all(ge(a,0)) && all(a==floor(a)))
         eidType = 'mustBeTwoPositiveUnsignedIntegers:notTwoPositiveUnsignedIntegers';
        msgType = 'Input must be two positive unsigned integers.';
        throwAsCaller(MException(eidType,msgType))
    end
end