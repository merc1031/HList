{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE EmptyDataDecls #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverlappingInstances#-}
{-# LANGUAGE UndecidableInstances#-}

{-

   (C) 2004, Oleg Kiselyov, Ralf Laemmel, Keean Schupke

   This is a main module for exercising a model with generic type
   cast and generic type equality. Because of generic type equality,
   this model works with GHC but it does not work with Hugs.

   Note: even though there are no overlapping instances in *this*
   module, one must still enable overlapping instances here; otherwise
   overlapping (for type equality) is not resolved properly for the
   imported modules.

-}

module MainGhcGeneric1 (

{-
 module Datatypes2,
 module Data.HList.CommonMain,
 module Data.HList.TypeEqO,
 module Data.HList.Label3,
-- mainExport
-}

) where

import Datatypes2
-- import Data.HList.CommonMain -- hiding (HDeleteMany, hDeleteMany)
import Data.HList.FakePrelude
import Data.HList.HListPrelude
import Data.HList.HArray

{-
import Data.HList.RecordAdv
import Data.HList.TypeEqO
import Data.HList.Label3
import Data.HList.RecordP
-}


-- --------------------------------------------------------------------------

type Animal =  '[Key,Name,Breed,Price]

angus :: HList Animal
angus =  HCons (Key 42)
           (HCons (Name "Angus")
           (HCons  Cow
           (HCons (Price 75.5)
            HNil)))

tList1 = hFoldr (HSeq HShow) (return () :: IO ()) angus
{-
 Key 42
 Name "Angus"
 Cow
 Price 75.5
-}

tList2 = print $ hAppend angus angus
{-
H[Key 42, Name "Angus", Cow, Price 75.5, Key 42, Name "Angus", Cow, Price 75.5]
-}


tListBasic = putStrLn "\nBasic HList tests" >>
	     sequence_ [tList1, tList2]

testHArray = putStrLn "\ntestHArray" >>
  sequence_ [ myProj1
  ]

myProj1 = print $ hProjectByHNats (hNats (HCons hZero (HCons hZero HNil))) angus
-- H[Key 42, Key 42]
-- XXX I don't duplicate at present!

myProj2 = print $ 
	  hProjectByHNats (hNats (HCons hZero (HCons (hSucc hZero) HNil))) angus
-- H[Key 42, Name "Angus"]

myProj2' = print $ 
	  hProjectByHNats (undefined::Proxy ['HZero, 'HSucc 'HZero]) angus
-- H[Key 42, Name "Angus"]

myProj3 = hProjectAwayByHNats (hNats (HCons hZero HNil)) angus
-- H[Name "Angus", Cow, Price 75.5]

{-
testHArray = (myProj1,myProj2,myProj3,myProj4)
 where
  myProj4 = hSplitByHNats (HCons hZero (HCons (hSucc hZero) HNil)) angus
-}

{-
*HArray> myProj3
HCons (Name "Angus") (HCons Cow (HCons (Price 75.5) HNil))

*HArray> myProj4
(HCons (Key 42) (HCons (Name "Angus") HNil),HCons Cow (HCons (Price 75.5) HNil)

-}

{-
testHOccurs = (testHOccurs1,testHOccurs2,testHOccurs3,testHOccurs4)
 where
  testHOccurs1 = hOccurs angus :: Breed
  testHOccurs2 = hOccurs (TIP (HCons 1 HNil))
  testHOccurs3 = null $ hOccurs (TIP (HCons [] HNil))
  testHOccurs4 = hProject angus :: (HCons Key (HCons Name HNil))

testTypeIndexed =   ( typeIdx1
                  , ( typeIdx2
                  , ( typeIdx3
                  , ( typeIdx4
                  , ( typeIdx5
                  , ( typeIdx6 ))))))
 where
  typeIdx1 = hDeleteMany (proxy::Proxy Name) angus
  typeIdx2 = hExtend BSE angus
  typeIdx3 = hUpdateAtType Sheep typeIdx1
  typeIdx4 = hDeleteAtProxy (proxy::Proxy Breed) typeIdx2
  typeIdx5 = hProjectByProxies (HCons (proxy::Proxy Breed) HNil) angus
  typeIdx6 = fst $ hSplitByProxies (HCons (proxy::Proxy Breed) HNil) angus

-- |
-- This example from the TIR paper challenges singleton lists.
-- Thanks to the HW 2004 reviewer who pointed out the value of this example.
-- We note that the explicit type below is richer than the inferred type.
-- This richer type is needed for making this operation more polymorphic.
-- That is, /a)/ would not work without the explicit type, while it would:
--
-- >  a)  ((+) (1::Int)) $ snd $ tuple oneTrue
-- >  b)  ((+) (1::Int)) $ fst $ tuple oneTrue

tuple :: ( HOccurs e1 (TIP l)
         , HType2HNat e1 l n
         , HDeleteAtHNat n l l'
         , HOccurs e2 (TIP l')
         , HOccurs e2 (TIP l)
         , HType2HNat e2 l n'
         , HDeleteAtHNat n' l l''
         , HOccurs e1 (TIP l'')
         ) =>
              TIP l -> (e1, e2)

tuple (TIP l) = let
                 x  = hOccurs (TIP l)
                 l' = hDeleteAtProxy (toProxy x) l
                 y  = hOccurs (TIP l')
                in (x,y)


-- | A specific tuple
-- Need to import an instance of TypeEq to be able to run the examples

oneTrue :: TIP (HCons Int (HCons Bool HNil))
oneTrue = hExtend (1::Int) (hExtend True emptyTIP)

testTuple =   ( testTuple1
            , ( testTuple2
            , ( testTuple3
            , ( testTuple4
            , ( testTuple5
              )))))
 where
  testTuple1 = let (a,b) = tuple oneTrue in (a+(1::Int), not b)
  testTuple2 = let b = not $ fst $ tuple oneTrue in (1::Int,b)
  testTuple3 = tuple oneTrue == (1::Int,True)
  testTuple4 = ((+) (1::Int)) $ fst $ tuple oneTrue
  -- requires explicit type for tuple
  testTuple5 = ((+) (1::Int)) $ snd $ tuple oneTrue

myTipyCow = TIP angus

animalKey :: ( SubType l (TIP Animal) -- explicit
             , HOccurs Key l          -- implicit
             ) => l -> Key
animalKey = hOccurs

animalish :: SubType l (TIP Animal) => l -> l
animalish = id
animalKey' l = hOccurs (animalish l) :: Key

testTIP = (testTIP1,testTIP2,testTIP3,testTIP4)
 where
  testTIP1 = hOccurs myTipyCow :: Breed
  testTIP2 = hExtend BSE myTipyCow
  testTIP3 = hExtend Sheep $ tipyDelete (proxy::Proxy Breed) myTipyCow
  testTIP4 = tipyUpdate Sheep myTipyCow

data MyNS = MyNS -- a name space for record labels

key   = firstLabel MyNS  (undefined::DKey)
name  = nextLabel  key   (undefined::DName)
breed = nextLabel  name  (undefined::DBreed)
price = nextLabel  breed (undefined::DPrice)
unpricedAngus =  key    .=. (42::Integer)
             .*. name   .=. "Angus"
             .*. breed  .=. Cow
             .*. emptyRecord

data DKey;   instance Show DKey   where show _ = "key"
data DName;  instance Show DName  where show _ = "name"
data DBreed; instance Show DBreed where show _ = "breed"
data DPrice; instance Show DPrice where show _ = "price"

getKey l = hLookupByLabel key l

testRecords =   ( test1 
              , ( test2
              , ( test3 
              , ( test4
              , ( test5
              , ( test6
	      , (test7, test81, test82, test83, test84, test85)
                ))))))
 where
  test1 = unpricedAngus
  test2 = test1 .!. breed
  test3 = hDeleteAtLabel breed test1
  test4 = breed .=. Sheep .@. test1
  test5 = price .=. 8.8 .*. test1
  test6 = hProjectByLabels (HCons breed (HCons price HNil)) test5
  -- test7 should have the same type as test1 and test4 but
  -- with the different order of labels
  -- test7 is even the same value as test4, modulo field order
  test7 = hExtend (newLVPair breed Sheep) test3
  test81 = equivR test1 test3 -- HNothing
  test82 = let HJust (r17,r71) = equivR test1 test7 in (r17 test1,r71 test7)
  test83 = let HJust (r17,r71) = 
		   equivR test1 test7 in show (r17 test1) == show test7
  test84 = let HJust (r47,r74) = 
		   equivR test4 test7 in (show (r47 test4) == show test7,
					  show (r74 test7) == show test4)
  test85 = let HJust (r7,r7') = 
		   equivR test7 test7 in show (r7 test7) == show (r7' test7)

testRecordsP =   ( test1 
		 , ( test2
		 , ( test3 
		 , ( test4
		 , ( test5
		 , ( test6
                   ))))))
 where
--  test1 = mkRecordP (undefined::Animal) angus
  test1 = record_r2p unpricedAngus
  test2 = test1 .!. breed
  test3 = hDeleteAtLabelP breed test1
--  test4 = test1 .@. breed .=. Sheep
  test4 = hExtend (newLVPair breed Sheep) test3
  test5 = price .=. 8.8 .*. test1
  test6 = fst $ h2projectByLabels (HCons breed (HCons price HNil)) test5


type AnimalCol = Key :+: Name :+: Breed :+: Price :+: HNil

testTIC = (myCol,test2,test3)
 where
  myCol = mkTIC Cow :: TIC AnimalCol
  test2 = unTIC myCol :: Maybe Breed
  test3 = unTIC myCol :: Maybe Price

{-

myCol = mkTIC Cow :: TIC AnimalCol

*TIC> unTIC myCol :: Maybe Breed
Just Cow
*TIC> unTIC myCol :: Maybe Price
Nothing
*TIC> mkTIC "42" :: TIC AnimalCol
Type error ...
*TIC> unTIC myCol :: Maybe String
Type error ...

-}

testVariant = (testVar1,(testVar2,(testVar3)))
 where
  animalVar =  key   .=. (proxy::Proxy Integer)
           .*. name  .=. (proxy::Proxy String)
           .*. breed .=. (proxy::Proxy Breed)
           .*. emptyRecord
  testVar1 = mkVariant name "angus" animalVar
  testVar2 = unVariant key testVar1
  testVar3 = unVariant name testVar1

-- --------------------------------------------------------------------------

main = mainExport
mainExport
   = print $   ( testHArray
               , ( testHOccurs
               , ( testTypeIndexed
               , ( testTuple
               , ( testTIP
               , ( testRecords
               , ( testRecordsP
               , ( testTIC
               , ( testVariant
               )))))))))

-}
