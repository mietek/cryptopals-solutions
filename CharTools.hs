module CharTools where

import Data.Bits ((.|.), (.&.), shiftL, shiftR, testBit, xor)
import qualified Data.Char as C
import Data.Word (Word8)


chr :: Word8 -> Char
chr n = C.chr (fromIntegral n)

ord :: Char -> Word8
ord c = fromIntegral (C.ord c)


isPrint :: Char -> Bool
isPrint c =
    c == '\t' ||
    c == '\n' ||
    c >= ' ' && c <= '~'

isLetter :: Char -> Bool
isLetter c =
    c >= 'a' && c <= 'z' ||
    c >= 'A' && c <= 'Z'

isHexDigit :: Char -> Bool
isHexDigit c =
    c >= '0' && c <= '9' ||
    c >= 'a' && c <= 'f' ||
    c >= 'A' && c <= 'F'

isB64Digit :: Char -> Bool
isB64Digit c =
    c >= 'A' && c <= 'Z' ||
    c >= 'a' && c <= 'z' ||
    c >= '0' && c <= '9' ||
    c == '+' ||
    c == '/'


toHexDigit :: Word8 -> Char
toHexDigit n
  | n >= 0 && n <= 9 = chr (ord '0' + n)
  | n >= 10 && n <= 15 = chr (ord 'a' - 10 + n)
  | otherwise = error ("toHexDigit: invalid number " ++ show n)

fromHexDigit :: Char -> Word8
fromHexDigit c
  | c >= '0' && c <= '9' = ord c - ord '0'
  | c >= 'a' && c <= 'f' = ord c - ord 'a' + 10
  | c >= 'A' && c <= 'F' = ord c - ord 'A' + 10
  | otherwise = error ("fromHexDigit: invalid digit " ++ show c)


toHexPair :: [Char] -> [Char]
toHexPair [c] = toHexPair' c
toHexPair cs = error ("toHexPair: invalid input " ++ show cs)

fromHexPair :: [Char] -> [Char]
fromHexPair [c1, c2] = fromHexPair' c1 c2
fromHexPair cs = error ("fromHexPair: invalid input " ++ show cs)


toHexPair' :: Char -> [Char]
toHexPair' c = map toHexDigit [k1, k2]
  where
    n = ord c
    k1 = (n .&. 0xF0) `shiftR` 4
    k2 = n .&. 0x0F

fromHexPair' :: Char -> Char -> [Char]
fromHexPair' c1 c2 = map chr [n]
  where
    n = (k1 `shiftL` 4) .|. k2
    [k1, k2] = map fromHexDigit [c1, c2]


toB64Digit :: Word8 -> Char
toB64Digit n
  | n >= 0 && n <= 25 = chr (ord 'A' + n)
  | n >= 26 && n <= 51 = chr (ord 'a' - 26 + n)
  | n >= 52 && n <= 61 = chr (ord '0' - 52 + n)
  | n == 62 = '+'
  | n == 63 = '/'
  | otherwise = error ("toB64Digit: invalid number " ++ show n)

fromB64Digit :: Char -> Word8
fromB64Digit c
  | c >= 'A' && c <= 'Z' = ord c - ord 'A'
  | c >= 'a' && c <= 'z' = ord c - ord 'a' + 26
  | c >= '0' && c <= '9' = ord c - ord '0' + 52
  | c == '+' = 62
  | c == '/' = 63
  | otherwise = error ("fromB64Digit: invalid digit " ++ show c)


toB64Quad :: [Char] -> [Char]
toB64Quad [c1] = take 2 (toB64Quad' c1 '\NUL' '\NUL') ++ "=="
toB64Quad [c1, c2] = take 3 (toB64Quad' c1 c2 '\NUL') ++ "="
toB64Quad [c1, c2, c3] = toB64Quad' c1 c2 c3
toB64Quad cs = error ("toB64Quad: invalid input " ++ show cs)

fromB64Quad :: [Char] -> [Char]
fromB64Quad [c1, c2] = take 1 (fromB64Quad' c1 c2 '=' '=')
fromB64Quad [c1, c2, '=', '='] = take 1 (fromB64Quad' c1 c2 '=' '=')
fromB64Quad [c1, c2, c3] = take 2 (fromB64Quad' c1 c2 c3 '=')
fromB64Quad [c1, c2, c3, '='] = take 2 (fromB64Quad' c1 c2 c3 '=')
fromB64Quad [c1, c2, c3, c4] = fromB64Quad' c1 c2 c3 c4
fromB64Quad cs = error ("fromB64Quad: invalid input " ++ show cs)


toB64Quad' :: Char -> Char -> Char -> [Char]
toB64Quad' c1 c2 c3 = map toB64Digit [k1, k2, k3, k4]
  where
    k1 = (n1 .&. 0xFC) `shiftR` 2
    k2 = ((n1 .&. 0x03) `shiftL` 4) .|. ((n2 .&. 0xF0) `shiftR` 4)
    k3 = ((n2 .&. 0x0F) `shiftL` 2) .|. ((n3 .&. 0xC0) `shiftR` 6)
    k4 = n3 .&. 0x3F
    [n1, n2, n3] = map ord [c1, c2, c3]

fromB64Quad' :: Char -> Char -> Char -> Char -> [Char]
fromB64Quad' c1 c2 c3 c4 = map chr [n1, n2, n3]
  where
    n1 = (k1 `shiftL` 2) .|. ((k2 .&. 0x30) `shiftR` 4)
    n2 = ((k2 .&. 0x0F) `shiftL` 4) .|. ((k3 .&. 0x3C) `shiftR` 2)
    n3 = ((k3 .&. 0x03) `shiftL` 6) .|. k4
    [k1, k2, k3, k4] = map fromB64Digit [c1, c2, c3, c4]


xorChar :: Char -> Char -> Char
xorChar k c = chr (ord k `xor` ord c)


hammingDistanceChar :: Char -> Char -> Double
hammingDistanceChar c1 c2 = realToFrac (sum (map (fromEnum . testBit x) [0 .. 7])) / 8
  where
    x = ord c1 `xor` ord c2
