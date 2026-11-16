UNIT W32Defs;
{ Win32 types and constants for 16-bit code.
  Reconstructed from the compiled code in PLAYER32.DLL; names not used by the
  surviving sources are guesses. }
INTERFACE

TYPE Handle32=LongInt;
     pRect32=^tRect32;
     tRect32=RECORD
       Left,Top,Right,Bottom:LongInt;
     END;

CONST { set up by W32Base }
      Win32Available:WordBool=False;
      hKernel32 :LongInt=0;
      hUser32   :LongInt=0;
      hGDI32    :LongInt=0;
      hShell32  :LongInt=0;
      hAdvapi32 :LongInt=0;
      hMPR      :LongInt=0;
      hWOW32    :LongInt=0;
      hVersion  :LongInt=0;
      Reserved1 :LongInt=0;  { purpose unknown (6 unreferenced bytes in the binaries) }
      Reserved2 :Word=0;

CONST { own section: smart linking drops it from MOD4WIN.EXE, which doesn't use it }
      INVALID_HANDLE_VALUE:Handle32=-1;

CONST
      GENERIC_READ         =$80000000;
      GENERIC_WRITE        =$40000000;

      FILE_SHARE_READ      =$00000001;
      FILE_SHARE_WRITE     =$00000002;

      CREATE_NEW           =1;
      CREATE_ALWAYS        =2;
      OPEN_EXISTING        =3;
      OPEN_ALWAYS          =4;
      TRUNCATE_EXISTING    =5;

      FILE_ATTRIBUTE_READONLY =$00000001;
      FILE_ATTRIBUTE_HIDDEN   =$00000002;
      FILE_ATTRIBUTE_SYSTEM   =$00000004;
      FILE_ATTRIBUTE_DIRECTORY=$00000010;
      FILE_ATTRIBUTE_ARCHIVE  =$00000020;
      FILE_ATTRIBUTE_NORMAL   =$00000080;

      FILE_BEGIN           =0;
      FILE_CURRENT         =1;
      FILE_END             =2;

IMPLEMENTATION
END.
