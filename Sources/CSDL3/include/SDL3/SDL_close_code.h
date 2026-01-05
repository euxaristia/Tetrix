/*
  Minimal SDL3 close_code header - Swift-native replacement
  Reverses the effects of SDL_begin_code.h
*/

#ifndef SDL_begin_code_h
#error SDL_close_code.h included without matching SDL_begin_code.h
#endif
#undef SDL_begin_code_h

/* Reset structure packing at previous byte alignment */
#if defined(_MSC_VER) || defined(__MWERKS__) || defined(__BORLANDC__)
#ifdef __BORLANDC__
#pragma nopackwarning
#endif
#pragma pack(pop)
#endif
