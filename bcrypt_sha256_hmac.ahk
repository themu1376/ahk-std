;size := bcrypt_sha256_hmac(MESSAGE, SECRET, hash)
;crypt := CryptBinaryToStringBASE64(&hash, size)

bcrypt_sha256_hmac(string, hmac, ByRef hash)
{
   static BCRYPT_SHA256_ALGORITHM     := "SHA256"
        , BCRYPT_ALG_HANDLE_HMAC_FLAG := 0x00000008
        , BCRYPT_OBJECT_LENGTH        := "ObjectLength"
        , BCRYPT_HASH_LENGTH          := "HashDigestLength"

   if !hBCRYPT := DllCall("LoadLibrary", Str, "bcrypt.dll", Ptr)
      throw Exception("Failed to load bcrypt.dll", -1)

   NTSTATUS := DllCall("bcrypt\BCryptOpenAlgorithmProvider", PtrP, hAlgo, Str, BCRYPT_SHA256_ALGORITHM, Ptr, 0, UInt, BCRYPT_ALG_HANDLE_HMAC_FLAG, UInt)
   if (NTSTATUS != 0)
      throw Exception("BCryptOpenAlgorithmProvider: " Format("0x{:X}", NTSTATUS), -1)

   NTSTATUS := DllCall("bcrypt\BCryptGetProperty", Ptr, hAlgo, Str, BCRYPT_OBJECT_LENGTH, UIntP, cbHashObject, UInt, 4, UIntP, cbResult, UInt, 0, UInt)
   if (NTSTATUS != 0)
      throw Exception("BCryptGetProperty: " Format("0x{:X}", NTSTATUS), -1)

   NTSTATUS := DllCall("bcrypt\BCryptGetProperty", Ptr, hAlgo, Str, BCRYPT_HASH_LENGTH, UIntP, cbHash, UInt, 4, UIntP, cbResult, UInt, 0, UInt)
   if (NTSTATUS != 0)
      throw Exception("BCryptGetProperty: " Format("0x{:X}", NTSTATUS), -1)

   VarSetCapacity(pbHashObject, cbHashObject, 0), VarSetCapacity(pbSecret, StrPut(hmac, "UTF-8"), 0), cbSecret := StrPut(hmac, &pbSecret, "UTF-8") - 1
   NTSTATUS := DllCall("bcrypt\BCryptCreateHash", Ptr, hAlgo, PtrP, hHash, Ptr, &pbHashObject, UInt, cbHashObject, Ptr, &pbSecret, UInt, cbSecret, UInt, 0, UInt)
   if (NTSTATUS != 0)
      throw Exception("BCryptCreateHash: " Format("0x{:X}", NTSTATUS), -1)

   VarSetCapacity(pbInput, StrPut(string, "UTF-8"), 0), cbInput := StrPut(string, &pbInput, "UTF-8") - 1
   NTSTATUS := DllCall("bcrypt\BCryptHashData", Ptr, hHash, Ptr, &pbInput, UInt, cbInput, UInt, 0, UInt)
   if (NTSTATUS != 0)
      throw Exception("BCryptHashData: " Format("0x{:X}", NTSTATUS), -1)

   VarSetCapacity(hash, cbHash, 0)
   NTSTATUS := DllCall("bcrypt\BCryptFinishHash", Ptr, hHash, Ptr, &hash, UInt, cbHash, UInt, 0, UInt)
   if (NTSTATUS != 0)
      throw Exception("BCryptFinishHash: " Format("0x{:X}", NTSTATUS), -1)

   DllCall("bcrypt\BCryptDestroyHash", Ptr, hHash)
   DllCall("bcrypt\BCryptCloseAlgorithmProvider", Ptr, hAlgo, UInt, 0)
   DllCall("FreeLibrary", Ptr, hBCRYPT)
   Return cbHash
}

CryptBinaryToStringBASE64(pData, bytes, NOCRLF := true)
{
	static CRYPT_STRING_BASE64 := 1, CRYPT_STRING_NOCRLF := 0x40000000
	CRYPT := CRYPT_STRING_BASE64 | (NOCRLF ? CRYPT_STRING_NOCRLF : 0)
	
	DllCall("Crypt32\CryptBinaryToString", Ptr, pData, UInt, bytes, UInt, CRYPT, Ptr, 0, UIntP, chars)
	VarSetCapacity(outData, chars << !!A_IsUnicode)
	DllCall("Crypt32\CryptBinaryToString", Ptr, pData, UInt, bytes, UInt, CRYPT, Str, outData, UIntP, chars)
	Return outData
}