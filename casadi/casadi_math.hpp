/*
 *    This file is part of CasADi.
 *
 *    CasADi -- A symbolic framework for dynamic optimization.
 *    Copyright (C) 2010 by Joel Andersson, Moritz Diehl, K.U.Leuven. All rights reserved.
 *
 *    CasADi is free software; you can redistribute it and/or
 *    modify it under the terms of the GNU Lesser General Public
 *    License as published by the Free Software Foundation; either
 *    version 3 of the License, or (at your option) any later version.
 *
 *    CasADi is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *    Lesser General Public License for more details.
 *
 *    You should have received a copy of the GNU Lesser General Public
 *    License along with CasADi; if not, write to the Free Software
 *    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

#ifndef CASADI_MATH_HPP
#define CASADI_MATH_HPP

#include "casadi_calculus.hpp"
namespace CasADi{

template<template<int> class F>
bool operation_checker(unsigned int op){
  switch(op){
    case OP_ASSIGN:     return F<OP_ASSIGN>::check;
    case ADD:           return F<ADD>::check;
    case SUB:           return F<SUB>::check;
    case MUL:           return F<MUL>::check;
    case DIV:           return F<DIV>::check;
    case NEG:           return F<NEG>::check;
    case EXP:           return F<EXP>::check;
    case LOG:           return F<LOG>::check;
    case POW:           return F<POW>::check;
    case CONSTPOW:      return F<CONSTPOW>::check;
    case SQRT:          return F<SQRT>::check;
    case SIN:           return F<SIN>::check;
    case COS:           return F<COS>::check;
    case TAN:           return F<TAN>::check;
    case ASIN:          return F<ASIN>::check;
    case ACOS:          return F<ACOS>::check;
    case ATAN:          return F<ATAN>::check;
    case STEP:          return F<STEP>::check;
    case FLOOR:         return F<FLOOR>::check;
    case CEIL:          return F<CEIL>::check;
    case EQUALITY:      return F<EQUALITY>::check;
    case FABS:          return F<FABS>::check;
    case SIGN:          return F<SIGN>::check;
    case ERF:           return F<ERF>::check;
    case FMIN:          return F<FMIN>::check;
    case FMAX:          return F<FMAX>::check;
    case INV:           return F<INV>::check;
    case SINH:          return F<SINH>::check;
    case COSH:          return F<COSH>::check;
    case TANH:          return F<TANH>::check;
    case OP_CONST:      return F<OP_CONST>::check;
    case OP_CALL:      	 return F<OP_CALL>::check;
    case OP_VAR:      	 return F<OP_VAR>::check;
    case OP_OUTPUT:     return F<OP_OUTPUT>::check;
    case ERFINV:        return F<ERFINV>::check;
    case OP_PRINTME:    return F<OP_PRINTME>::check;
    case ATAN2:         return F<ATAN2>::check;
  }
};


/// Easy access to all the functions for a particular type
template<typename T>
struct casadi_math{

  /** \brief Evaluate a built in function */
  static inline void fun(unsigned char op, const T& x, const T& y, T& f);
  
  /** \brief Evaluate a built in derivative function */
  static inline void der(unsigned char op, const T& x, const T& y, const T& f, T* d);

  /** \brief Evaluate the function and the derivative function */
  static inline void derF(unsigned char op, const T& x, const T& y, T& f, T* d);
  
  /** \brief Number of dependencies */
  static inline int ndeps(unsigned char op);
  
  /** \brief Print */
  static inline void print(unsigned char op, std::ostream &stream, const std::string& x, const std::string& y);
  static inline void printPre(unsigned char op, std::ostream &stream);
  static inline void printSep(unsigned char op, std::ostream &stream);
  static inline void printPost(unsigned char op, std::ostream &stream);
};

/// Specialize the class so that it can be used with integer type
template<>
struct casadi_math<int>{

  /** \brief Evaluate a built in function */
  static inline void fun(unsigned char op, const int& x, const int& y, int& f){
    double f_real(f);
    casadi_math<double>::fun(op,double(x),double(y),f_real);
    f = int(f_real);
  }
  
  /** \brief Evaluate a built in derivative function */
  static inline void der(unsigned char op, const int& x, const int& y, const int& f, int* d){
    double d_real[2] = {double(d[0]),double(d[1])};
    casadi_math<double>::der(op,double(x),double(y),double(f),d_real);
    d[0] = int(d_real[0]);
    d[1] = int(d_real[1]);
  }

  /** \brief Evaluate the function and the derivative function */
  static inline void derF(unsigned char op, const int& x, const int& y, int& f, int* d){
    double d_real[2] = {double(d[0]),double(d[1])};
    double f_real(f);
    casadi_math<double>::derF(op,double(x),double(y),f_real,d_real);
    f = int(f_real);
    d[0] = int(d_real[0]);
    d[1] = int(d_real[1]);
  }
  
  /** \brief Number of dependencies */
  static inline int ndeps(unsigned char op){ return casadi_math<double>::ndeps(op);}
  
  /** \brief Print */
  static inline void print(unsigned char op, std::ostream &stream, const std::string& x, const std::string& y){ casadi_math<double>::print(op,stream,x,y);}
  static inline void printPre(unsigned char op, std::ostream &stream){ casadi_math<double>::printPre(op,stream);}
  static inline void printSep(unsigned char op, std::ostream &stream){ casadi_math<double>::printSep(op,stream);}
  static inline void printPost(unsigned char op, std::ostream &stream){ casadi_math<double>::printPost(op,stream);}
};

// Template implementations

template<typename T>
inline void casadi_math<T>::fun(unsigned char op, const T& x, const T& y, T& f){
// NOTE: We define the implementation in a preprocessor macro to be able to force inlining, and to allow extensions in the VM
#define CASADI_MATH_FUN_BUILTIN(X,Y,F,C,OFF) \
    case OP_ASSIGN+OFF:    C<OP_ASSIGN>::fcn(X,Y,F);        break;\
    case ADD+OFF:       C<ADD>::fcn(X,Y,F);           break;\
    case SUB+OFF:       C<SUB>::fcn(X,Y,F);           break;\
    case MUL+OFF:       C<MUL>::fcn(X,Y,F);           break;\
    case DIV+OFF:       C<DIV>::fcn(X,Y,F);           break;\
    case NEG+OFF:       C<NEG>::fcn(X,Y,F);           break;\
    case EXP+OFF:       C<EXP>::fcn(X,Y,F);           break;\
    case LOG+OFF:       C<LOG>::fcn(X,Y,F);           break;\
    case POW+OFF:       C<POW>::fcn(X,Y,F);           break;\
    case CONSTPOW+OFF:  C<CONSTPOW>::fcn(X,Y,F);      break;\
    case SQRT+OFF:      C<SQRT>::fcn(X,Y,F);          break;\
    case SIN+OFF:       C<SIN>::fcn(X,Y,F);           break;\
    case COS+OFF:       C<COS>::fcn(X,Y,F);           break;\
    case TAN+OFF:       C<TAN>::fcn(X,Y,F);           break;\
    case ASIN+OFF:      C<ASIN>::fcn(X,Y,F);          break;\
    case ACOS+OFF:      C<ACOS>::fcn(X,Y,F);          break;\
    case ATAN+OFF:      C<ATAN>::fcn(X,Y,F);          break;\
    case STEP+OFF:      C<STEP>::fcn(X,Y,F);          break;\
    case FLOOR+OFF:     C<FLOOR>::fcn(X,Y,F);         break;\
    case CEIL+OFF:      C<CEIL>::fcn(X,Y,F);          break;\
    case EQUALITY+OFF:  C<EQUALITY>::fcn(X,Y,F);      break;\
    case FABS+OFF:      C<FABS>::fcn(X,Y,F);          break;\
    case SIGN+OFF:     C<SIGN>::fcn(X,Y,F);           break;\
    case ERF+OFF:       C<ERF>::fcn(X,Y,F);           break;\
    case FMIN+OFF:      C<FMIN>::fcn(X,Y,F);          break;\
    case FMAX+OFF:      C<FMAX>::fcn(X,Y,F);          break;\
    case INV+OFF:       C<INV>::fcn(X,Y,F);           break;\
    case SINH+OFF:      C<SINH>::fcn(X,Y,F);          break;\
    case COSH+OFF:      C<COSH>::fcn(X,Y,F);          break;\
    case TANH+OFF:      C<TANH>::fcn(X,Y,F);          break;\
    case ATAN2+OFF:     C<ATAN2>::fcn(X,Y,F);        break; \
    case ERFINV+OFF:    C<ERFINV>::fcn(X,Y,F);        break;\
    case OP_PRINTME+OFF:   C<OP_PRINTME>::fcn(X,Y,F);       break;
  
  #define CASADI_MATH_FUN_ALL_BUILTIN(X,Y,F) \
    CASADI_MATH_FUN_BUILTIN(X,Y,F,BinaryOperation,0)\
    CASADI_MATH_FUN_BUILTIN(X,Y,F,AddBinaryOperation,NUM_BUILT_IN_OPS)\
    CASADI_MATH_FUN_BUILTIN(X,Y,F,SubBinaryOperation,2*NUM_BUILT_IN_OPS)\
    CASADI_MATH_FUN_BUILTIN(X,Y,F,MulBinaryOperation,3*NUM_BUILT_IN_OPS)\
    CASADI_MATH_FUN_BUILTIN(X,Y,F,DivBinaryOperation,4*NUM_BUILT_IN_OPS)
  
  switch(op){
    CASADI_MATH_FUN_ALL_BUILTIN(x,y,f)
  }
}

template<typename T>
inline void casadi_math<T>::der(unsigned char op, const T& x, const T& y, const T& f, T* d){
// NOTE: We define the implementation in a preprocessor macro to be able to force inlining, and to allow extensions in the VM
#define CASADI_MATH_DER_BUILTIN(TYPE,X,Y,F,D) \
    case OP_ASSIGN:    BinaryOperation<OP_ASSIGN>::der(X,Y,F,D);     break;\
    case ADD:       BinaryOperation<ADD>::der(X,Y,F,D);        break;\
    case SUB:       BinaryOperation<SUB>::der(X,Y,F,D);        break;\
    case MUL:       BinaryOperation<MUL>::der(X,Y,F,D);        break;\
    case DIV:       BinaryOperation<DIV>::der(X,Y,F,D);        break;\
    case NEG:       BinaryOperation<NEG>::der(X,Y,F,D);        break;\
    case EXP:       BinaryOperation<EXP>::der(X,Y,F,D);        break;\
    case LOG:       BinaryOperation<LOG>::der(X,Y,F,D);        break;\
    case POW:       BinaryOperation<POW>::der(X,Y,F,D);        break;\
    case CONSTPOW:  BinaryOperation<CONSTPOW>::der(X,Y,F,D);   break;\
    case SQRT:      BinaryOperation<SQRT>::der(X,Y,F,D);       break;\
    case SIN:       BinaryOperation<SIN>::der(X,Y,F,D);        break;\
    case COS:       BinaryOperation<COS>::der(X,Y,F,D);        break;\
    case TAN:       BinaryOperation<TAN>::der(X,Y,F,D);        break;\
    case ASIN:      BinaryOperation<ASIN>::der(X,Y,F,D);       break;\
    case ACOS:      BinaryOperation<ACOS>::der(X,Y,F,D);       break;\
    case ATAN:      BinaryOperation<ATAN>::der(X,Y,F,D);       break;\
    case STEP:      BinaryOperation<STEP>::der(X,Y,F,D);       break;\
    case FLOOR:     BinaryOperation<FLOOR>::der(X,Y,F,D);      break;\
    case CEIL:      BinaryOperation<CEIL>::der(X,Y,F,D);       break;\
    case EQUALITY:  BinaryOperation<EQUALITY>::der(X,Y,F,D);   break;\
    case FABS:      BinaryOperation<FABS>::der(X,Y,F,D);       break;\
    case SIGN:      BinaryOperation<SIGN>::der(X,Y,F,D);       break;\
    case ERF:       BinaryOperation<ERF>::der(X,Y,F,D);        break;\
    case FMIN:      BinaryOperation<FMIN>::der(X,Y,F,D);       break;\
    case FMAX:      BinaryOperation<FMAX>::der(X,Y,F,D);       break;\
    case INV:       BinaryOperation<INV>::der(X,Y,F,D);        break;\
    case SINH:      BinaryOperation<SINH>::der(X,Y,F,D);       break;\
    case COSH:      BinaryOperation<COSH>::der(X,Y,F,D);       break;\
    case TANH:      BinaryOperation<TANH>::der(X,Y,F,D);       break;\
    case ATAN2:      BinaryOperation<ATAN2>::der(X,Y,F,D);       break;\
    case ERFINV:    BinaryOperation<ERFINV>::der(X,Y,F,D);     break;\
    case OP_PRINTME:   BinaryOperation<OP_PRINTME>::der(X,Y,F,D);    break;
  
  switch(op){
    CASADI_MATH_DER_BUILTIN(T,x,y,f,d)
  }
}


template<typename T>
inline void casadi_math<T>::derF(unsigned char op, const T& x, const T& y, T& f, T* d){
// NOTE: We define the implementation in a preprocessor macro to be able to force inlining, and to allow extensions in the VM
#define CASADI_MATH_DERF_BUILTIN(TYPE,X,Y,F,D) \
    case OP_ASSIGN:    DerBinaryOpertion<OP_ASSIGN>::derf(X,Y,F,D);        break;\
    case ADD:       DerBinaryOpertion<ADD>::derf(X,Y,F,D);        break;\
    case SUB:       DerBinaryOpertion<SUB>::derf(X,Y,F,D);        break;\
    case MUL:       DerBinaryOpertion<MUL>::derf(X,Y,F,D);        break;\
    case DIV:       DerBinaryOpertion<DIV>::derf(X,Y,F,D);        break;\
    case NEG:       DerBinaryOpertion<NEG>::derf(X,Y,F,D);        break;\
    case EXP:       DerBinaryOpertion<EXP>::derf(X,Y,F,D);        break;\
    case LOG:       DerBinaryOpertion<LOG>::derf(X,Y,F,D);        break;\
    case POW:       DerBinaryOpertion<POW>::derf(X,Y,F,D);        break;\
    case CONSTPOW:  DerBinaryOpertion<CONSTPOW>::derf(X,Y,F,D);   break;\
    case SQRT:      DerBinaryOpertion<SQRT>::derf(X,Y,F,D);       break;\
    case SIN:       DerBinaryOpertion<SIN>::derf(X,Y,F,D);        break;\
    case COS:       DerBinaryOpertion<COS>::derf(X,Y,F,D);        break;\
    case TAN:       DerBinaryOpertion<TAN>::derf(X,Y,F,D);        break;\
    case ASIN:      DerBinaryOpertion<ASIN>::derf(X,Y,F,D);       break;\
    case ACOS:      DerBinaryOpertion<ACOS>::derf(X,Y,F,D);       break;\
    case ATAN:      DerBinaryOpertion<ATAN>::derf(X,Y,F,D);       break;\
    case STEP:      DerBinaryOpertion<STEP>::derf(X,Y,F,D);       break;\
    case FLOOR:     DerBinaryOpertion<FLOOR>::derf(X,Y,F,D);      break;\
    case CEIL:      DerBinaryOpertion<CEIL>::derf(X,Y,F,D);       break;\
    case EQUALITY:  DerBinaryOpertion<EQUALITY>::derf(X,Y,F,D);   break;\
    case FABS:      DerBinaryOpertion<FABS>::derf(X,Y,F,D);        break;\
    case SIGN:      DerBinaryOpertion<SIGN>::derf(X,Y,F,D);        break;\
    case ERF:       DerBinaryOpertion<ERF>::derf(X,Y,F,D);        break;\
    case FMIN:      DerBinaryOpertion<FMIN>::derf(X,Y,F,D);       break;\
    case FMAX:      DerBinaryOpertion<FMAX>::derf(X,Y,F,D);       break;\
    case INV:       DerBinaryOpertion<INV>::derf(X,Y,F,D);         break;\
    case SINH:      DerBinaryOpertion<SINH>::derf(X,Y,F,D);        break;\
    case COSH:      DerBinaryOpertion<COSH>::derf(X,Y,F,D);        break;\
    case TANH:      DerBinaryOpertion<TANH>::derf(X,Y,F,D);        break;\
    case ATAN2:      DerBinaryOpertion<ATAN2>::derf(X,Y,F,D);        break;\
    case ERFINV:    DerBinaryOpertion<ERFINV>::derf(X,Y,F,D);        break;\
    case OP_PRINTME:   DerBinaryOpertion<OP_PRINTME>::derf(X,Y,F,D);     break;
  
  switch(op){
    CASADI_MATH_DERF_BUILTIN(T,x,y,f,d)
  }
}

template<typename T>
inline int casadi_math<T>::ndeps(unsigned char op){
  switch(op){
    case ADD:
    case SUB:
    case MUL:
    case DIV:
    case POW:
    case CONSTPOW:
    case EQUALITY:
    case FMIN:
    case FMAX:
    case ATAN2:
    case OP_PRINTME:
      return 2;
    default:
      return 1;
  }
}

template<typename T>
inline void casadi_math<T>::print(unsigned char op, std::ostream &stream, const std::string& x, const std::string& y){
  if(ndeps(op)==2){
    printPre(op,stream);
    stream << x;
    printSep(op,stream);
    stream << y;
    printPost(op,stream);
  } else {
    printPre(op,stream);
    stream << x;
    printPost(op,stream);
  }
}

template<typename T>
inline void casadi_math<T>::printPre(unsigned char op, std::ostream &stream){
  switch(op){
    case OP_ASSIGN:                          break;
    case ADD:       stream << "(";        break;
    case SUB:       stream << "(";        break;
    case MUL:       stream << "(";        break;
    case DIV:       stream << "(";        break;
    case NEG:       stream << "(-";       break;
    case EXP:       stream << "exp(";     break;
    case LOG:       stream << "log(";     break;
    case POW:       stream << "pow(";     break;
    case CONSTPOW:  stream << "pow(";     break;
    case SQRT:      stream << "sqrt(";    break;
    case SIN:       stream << "sin(";     break;
    case COS:       stream << "cos(";     break;
    case TAN:       stream << "tan(";     break;
    case ASIN:      stream << "asin(";    break;
    case ACOS:      stream << "acos(";    break;
    case ATAN:      stream << "atan(";    break;
    case STEP:      stream << "(";        break;
    case FLOOR:     stream << "floor(";   break;
    case CEIL:      stream << "ceil(";    break;
    case EQUALITY:  stream << "(";        break;
    case FABS:      stream << "fabs(";    break;
    case SIGN:     stream << "sign(";   break;
    case ERF:       stream << "erf(";     break;
    case FMIN:      stream << "fmin(";    break;
    case FMAX:      stream << "fmax(";    break;
    case INV:       stream << "(1./";     break;
    case SINH:      stream << "sinh(";    break;
    case COSH:      stream << "cosh(";    break;
    case TANH:      stream << "tanh(";    break;
    case ATAN2:      stream << "atan2(";    break;
    case ERFINV:    stream << "erfinv(";  break;
    case OP_PRINTME:   stream << "printme("; break;
  }
}

template<typename T>
inline void casadi_math<T>::printSep(unsigned char op, std::ostream &stream){
  switch(op){
    case ADD:       stream << "+";        break;
    case SUB:       stream << "-";        break;
    case MUL:       stream << "*";        break;
    case DIV:       stream << "/";        break;
    case EQUALITY:  stream << "==";       break;
    default:        stream << ",";        break;
  }
}

template<typename T>
inline void casadi_math<T>::printPost(unsigned char op, std::ostream &stream){
  switch(op){
    case OP_ASSIGN:                          break;
    case STEP:      stream << ">=0)";     break;
    default:        stream << ")";        break;
  }
}

} // namespace CasADi

#endif //CASADI_MATH_HPP
