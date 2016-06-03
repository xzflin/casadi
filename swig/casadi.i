/*
 *    This file is part of CasADi.
 *
 *    CasADi -- A symbolic framework for dynamic optimization.
 *    Copyright (C) 2010-2014 Joel Andersson, Joris Gillis, Moritz Diehl,
 *                            K.U. Leuven. All rights reserved.
 *    Copyright (C) 2011-2014 Greg Horn
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


%module(package="casadi",directors=1) casadi

 // Include all public CasADi C++
%{
#include <casadi/casadi.hpp>
#include <casadi/core/casadi_interrupt.hpp>
%}

  /// Data structure in the target language holding data
#ifdef SWIGPYTHON
#define GUESTOBJECT PyObject
#elif defined(SWIGMATLAB)
#define GUESTOBJECT mxArray
#else
#define GUESTOBJECT void
#endif

// Define printing routine
#ifdef SWIGPYTHON
%{
  namespace casadi {
    // Redirect printout
    static void pythonlogger(const char* s, std::streamsize num, bool error) {
      if (error) {
        PySys_WriteStderr("%.*s", static_cast<int>(num), s);
      } else {
        PySys_WriteStdout("%.*s", static_cast<int>(num), s);
      }
    }

    static bool pythoncheckinterrupted() {
      return PyErr_CheckSignals();
    }


  }

%}
%init %{
  // Set logger functions
  casadi::Logger::writeWarn = casadi::pythonlogger;
  casadi::Logger::writeProg = casadi::pythonlogger;
  casadi::Logger::writeDebug = casadi::pythonlogger;
  casadi::Logger::writeAll = casadi::pythonlogger;

  // @jgillis: please document
  casadi::InterruptHandler::checkInterrupted = casadi::pythoncheckinterrupted;
%}
#elif defined(SWIGMATLAB)
%{
  namespace casadi {
    // Redirect printout to mexPrintf
    static void mexlogger(const char* s, std::streamsize num, bool error) {
      mexPrintf("%.*s", static_cast<int>(num), s);
    }

    // Flush the command window buffer (needed in gui mode)
    static void mexflush(bool error) {
      mexEvalString("drawnow('update');");
      mexEvalString("pause(0.0001);");
    }

    // Undocumented matlab feature
    extern "C" bool utIsInterruptPending();

    static bool mexcheckinterrupted() {
      return utIsInterruptPending();
    }
  }
%}
%init %{
  // Get full path
  mxArray *fullpath, *fullpath_cmd = mxCreateString("fullpath");
  mexCallMATLAB(1, &fullpath, 1, &fullpath_cmd, "mfilename");
  mxDestroyArray(fullpath_cmd);
  std::string path = mxArrayToString(fullpath);
  mxDestroyArray(fullpath);

  // Get file separator
  mxArray *filesep;
  mexCallMATLAB(1, &filesep, 0, 0, "filesep");
  std::string sep = mxArrayToString(filesep);
  mxDestroyArray(filesep);

  // Truncate at separator
  path = path.substr(0, path.rfind(sep));

  // Set library path
  casadi::GlobalOptions::setCasadiPath(path);

  // @jgillis: please document
  mxArray *warning_rhs[] = {mxCreateString("error"),

                            mxCreateString("SWIG:OverloadError")};
  mexCallMATLAB(0, 0, 2, warning_rhs, "warning");
  mxDestroyArray(warning_rhs[0]);
  mxDestroyArray(warning_rhs[1]);


  // Set logger functions
  casadi::Logger::writeWarn = casadi::mexlogger;
  casadi::Logger::writeProg = casadi::mexlogger;
  casadi::Logger::writeDebug = casadi::mexlogger;
  casadi::Logger::writeAll = casadi::mexlogger;
  casadi::Logger::flush = casadi::mexflush;

  // @jgillis: please document
  casadi::InterruptHandler::checkInterrupted = casadi::mexcheckinterrupted;
%}
#endif

// Turn off the warnings that certain methods are effectively ignored, this seams to be a false warning,
// for example vertcat(SXVector), vertcat(DMVector) and vertcat(MXVector) appears to work fine
#pragma SWIG nowarn=509,303,302

#define CASADI_EXPORT

// Incude cmath early on, see #622
%begin %{
#include <cmath>
#ifdef _XOPEN_SOURCE
#undef _XOPEN_SOURCE
#endif
#ifdef _POSIX_C_SOURCE
#undef _POSIX_C_SOURCE
#endif
%}

%ignore *::operator->;

#ifdef SWIGMATLAB
%rename(disp) repr;
#else
%ignore print;
%ignore repr;
#endif

%begin %{
#define SWIG_PYTHON_OUTPUT_TUPLE
%}

// Print representation
#ifdef SWIGMATLAB
#define SWIG_REPR disp
#else
#define SWIG_REPR __repr__
#endif

// Print description
#ifdef SWIGMATLAB
#define SWIG_STR print
#else
#define SWIG_STR __str__
#endif


//#endif // SWIGPYTHON


#ifdef SWIGPYTHON
%pythoncode %{

import contextlib

class _copyableObject(_object):
  def __copy__(self):
    return self.__class__(self)

  def __deepcopy__(self,dummy=None):
    return self.__class__(self)

_object = _copyableObject

_swig_repr_default = _swig_repr
def _swig_repr(self):
  if hasattr(self,'getRepresentation'):
    return self.getRepresentation()
  else:
    return _swig_repr_default(self)

%}
#endif // WITH_SWIGPYTHON

#if defined(SWIGPYTHON) || defined(SWIGMATLAB)
%include "doc_merged.i"
#else
%include "doc.i"
#endif

%feature("autodoc", "1");

%naturalvar;

// Make data members read-only
%immutable;

// Make sure that a copy constructor is created
%copyctor;

#ifndef SWIGXML
%feature("compactdefaultargs","1");
//%feature("compactdefaultargs","0") casadi::taylor; // taylor function has a default argument for which the namespace is not recognised by SWIG
%feature("compactdefaultargs","0") casadi::Function::generateCode; // buggy
#endif //SWIGXML

#ifdef SWIGMATLAB
// This is a first iteration for having
// beautified error messages in the Matlab iterface
%feature("matlabprepend") %{
      try
%}

%feature("matlabappend") %{
      catch err
        if (strcmp(err.identifier,'SWIG:RuntimeError') & strfind(err.message,'No matching function for overload function')==1)
          msg = [swig_typename_convertor_cpp2matlab(err.message) 'You have: ' strjoin(cellfun(@swig_typename_convertor_matlab2cpp,varargin,'UniformOutput',false),', ')];
          throwAsCaller(MException(err.identifier,msg));
        else
          rethrow(err);
        end
      end
%}

#endif // SWIGMATLAB

// STL
#ifdef SWIGXML
namespace std {
  template<class T> class vector {};
  template<class A, class B> class pair {};
  template<class A, class B> class map {};
}
#else // SWIGXML
%include "stl.i"
#endif // SWIGXML

// Exceptions handling
%include "exception.i"
%exception {
  try {
    $action
   } catch(const std::exception& e) {
    SWIG_exception(SWIG_RuntimeError, e.what());
  }
}

// Python sometimes takes an approach to not check, but just try.
// It expects a python error to be thrown.
%exception __int__ {
  try {
    $action
  } catch (const std::exception& e) {
    SWIG_exception(SWIG_RuntimeError, e.what());
  }
}

#ifdef WITH_PYTHON3
// See https://github.com/casadi/casadi/issues/701
// Recent numpys will only catch TypeError or ValueError in printing logic
%exception __bool__ {
 try {
    $action
  } catch (const std::exception& e) {
   SWIG_exception(SWIG_TypeError, e.what());
  }
}
#else
%exception __nonzero__ {
 try {
    $action
  } catch (const std::exception& e) {
   SWIG_exception(SWIG_TypeError, e.what());
  }
}
#endif

#ifdef SWIGPYTHON
%feature("director:except") {
	if ($error != NULL) {
    SWIG_PYTHON_THREAD_BEGIN_BLOCK;
    PyErr_Print();
    SWIG_PYTHON_THREAD_END_BLOCK;
		Swig::DirectorMethodException::raise("foo");
	}
}
#endif //SWIGPYTHON

#ifdef SWIGPYTHON

%{
#define SWIG_FILE_WITH_INIT
#include "numpy.hpp"
#define SWIG_PYTHON_CAST_MODE 1
%}

%init %{
import_array();
%}

#endif // SWIGPYTHON

%{
#define SWIG_Error_return(code, msg)  { std::cerr << "Error occured in CasADi SWIG interface code:" << std::endl << "  "<< msg << std::endl;SWIG_Error(code, msg); return 0; }
%}

#ifndef SWIGXML

%fragment("casadi_decl", "header") {
  namespace casadi {
    /* Check if Null or None */
    bool is_null(GUESTOBJECT *p);

    /* Typemaps from CasADi types to types in the interfaced language:
     *
     * to_ptr: Converts a pointer in interfaced language to C++:
     *   Input: GUESTOBJECT pointer p
     *   Output: Pointer to pointer: At input, pointer to pointer to temporary
     *   The routine will either:
     *     - Do nothing, if 0
     *     - Change the pointer
     *     - Change the temporary object
     *   Returns true upon success, else false
     *
     * from_ptr: Converts result from CasADi to interfaced language
     */

    // Basic types
    bool to_ptr(GUESTOBJECT *p, bool** m);
    GUESTOBJECT* from_ptr(const bool *a);
    bool to_ptr(GUESTOBJECT *p, int** m);
    GUESTOBJECT* from_ptr(const int *a);
    bool to_ptr(GUESTOBJECT *p, double** m);
    GUESTOBJECT* from_ptr(const double *a);
    bool to_ptr(GUESTOBJECT *p, std::string** m);
    GUESTOBJECT* from_ptr(const std::string *a);

    // std::vector
#ifdef SWIGMATLAB
    bool to_ptr(GUESTOBJECT *p, std::vector<double> **m);
    GUESTOBJECT* from_ptr(const std::vector<double> *a);
    bool to_ptr(GUESTOBJECT *p, std::vector<int>** m);
    GUESTOBJECT* from_ptr(const std::vector<int> *a);
    bool to_ptr(GUESTOBJECT *p, std::vector<std::string>** m);
    GUESTOBJECT* from_ptr(const std::vector<std::string> *a);
#endif // SWIGMATLAB
    template<typename M> bool to_ptr(GUESTOBJECT *p, std::vector<M>** m);
    template<typename M> GUESTOBJECT* from_ptr(const std::vector<M> *a);

    // std::pair
#ifdef SWIGMATLAB
    bool to_ptr(GUESTOBJECT *p, std::pair<int, int>** m);
    GUESTOBJECT* from_ptr(const std::pair<int, int>* a);
#endif // SWIGMATLAB
    template<typename M1, typename M2> bool to_ptr(GUESTOBJECT *p, std::pair<M1, M2>** m);
    template<typename M1, typename M2> GUESTOBJECT* from_ptr(const std::pair<M1, M2>* a);

    // std::map
    template<typename M> bool to_ptr(GUESTOBJECT *p, std::map<std::string, M>** m);
    template<typename M> GUESTOBJECT* from_ptr(const std::map<std::string, M> *a);

    // Slice
    bool to_ptr(GUESTOBJECT *p, casadi::Slice** m);
    GUESTOBJECT* from_ptr(const casadi::Slice *a);

    // Sparsity
    bool to_ptr(GUESTOBJECT *p, casadi::Sparsity** m);
    GUESTOBJECT* from_ptr(const casadi::Sparsity *a);

    // Matrix<>
    bool to_ptr(GUESTOBJECT *p, casadi::DM** m);
    GUESTOBJECT* from_ptr(const casadi::DM *a);
    bool to_ptr(GUESTOBJECT *p, casadi::IM** m);
    GUESTOBJECT* from_ptr(const casadi::IM *a);
    bool to_ptr(GUESTOBJECT *p, casadi::SX** m);
    GUESTOBJECT* from_ptr(const casadi::SX *a);

    // MX
    bool to_ptr(GUESTOBJECT *p, casadi::MX** m);
    GUESTOBJECT* from_ptr(const casadi::MX *a);

    // Function
    bool to_ptr(GUESTOBJECT *p, casadi::Function** m);
    GUESTOBJECT* from_ptr(const casadi::Function *a);

    // SXElem
    bool to_ptr(GUESTOBJECT *p, casadi::SXElem** m);
    GUESTOBJECT* from_ptr(const casadi::SXElem *a);

    // GenericType
    bool to_ptr(GUESTOBJECT *p, casadi::GenericType** m);
    GUESTOBJECT* from_ptr(const casadi::GenericType *a);

    // Same as to_ptr, but with pointer instead of pointer to pointer
    template<typename M> bool to_val(GUESTOBJECT *p, M* m);

    // Check if conversion is possible
    template<typename M> bool can_convert(GUESTOBJECT *p) { return to_ptr(p, static_cast<M**>(0));}

    // Assign to a vector, if conversion is allowed
    template<typename E, typename M> bool assign_vector(E* d, int sz, std::vector<M>** m);

    // Same as the above, but with reference instead of pointer
    template<typename M> GUESTOBJECT* from_ref(const M& m) { return from_ptr(&m);}

    // Specialization for std::vectors of booleans
    GUESTOBJECT* from_ref(std::vector<bool>::const_reference m) {
      bool tmp = m;
      return from_ptr(&tmp);
    }

    // Same as the above, but with a temporary object
    template<typename M> GUESTOBJECT* from_tmp(M m) { return from_ptr(&m);}
#ifdef SWIGMATLAB
    // Get sparsity pattern
    Sparsity get_sparsity(const mxArray* p);

    // Number of nonzeros
    size_t getNNZ(const mxArray* p);
#endif // SWIGMATLAB

  } // namespace CasADi
 }

%fragment("casadi_aux", "header", fragment="casadi_decl") {
  namespace casadi {
    template<typename M> bool to_val(GUESTOBJECT *p, M* m) {
      // Copy the pointer
      M *m2 = m;
      bool ret = to_ptr(p, m ? &m2 : 0);
      // If pointer changed, copy the object
      if (m!=m2) *m=*m2;
      return ret;
    }

    // Same as to_ptr, but with GenericType
    template<typename M> bool to_generic(GUESTOBJECT *p, GenericType** m) {
      if (m) {
        // Temporary
        M tmp, *tmp_ptr=&tmp;
        bool ret = to_ptr(p, &tmp_ptr);
        if (!ret) return ret;
        **m = GenericType(*tmp_ptr);
        return ret;
      } else {
        return to_ptr(p, static_cast<M**>(0));
      }
    }

    // Check if int
    template<typename T> struct is_int {
      static inline bool check() {return false;}
    };

    template<> struct is_int<int> {
      static inline bool check() {return true;}
    };

    // Traits for assign vector
    template<typename E, typename M> struct traits_assign_vector {
      inline static bool assign(E* d, int sz, std::vector<M>** m) {
        // Not allowed by default
        return false;
      }
    };

    // int-to-int
    template<> struct traits_assign_vector<int, int> {
      inline static bool assign(int* d, int sz, std::vector<int>** m) {
        if (m) **m = std::vector<int>(d, d+sz);
        return true;
      }
    };

    // long-to-int
    template<> struct traits_assign_vector<long, int> {
      inline static bool assign(long* d, int sz, std::vector<int>** m) {
        if (m) **m = std::vector<int>(d, d+sz);
        return true;
      }
    };

    // long-to-double
    template<> struct traits_assign_vector<long, double> {
      inline static bool assign(long* d, int sz, std::vector<double>** m) {
        if (m) **m = std::vector<double>(d, d+sz);
        return true;
      }
    };

    // int-to-double
    template<> struct traits_assign_vector<int, double> {
      inline static bool assign(int* d, int sz, std::vector<double>** m) {
        if (m) **m = std::vector<double>(d, d+sz);
        return true;
      }
    };

    // double-to-double
    template<> struct traits_assign_vector<double, double> {
      inline static bool assign(double* d, int sz, std::vector<double>** m) {
        if (m) **m = std::vector<double>(d, d+sz);
        return true;
      }
    };

    // Assign to a vector, if conversion is allowed
    template<typename E, typename M> bool assign_vector(E* d, int sz, std::vector<M>** m) {
      return traits_assign_vector<E, M>::assign(d, sz, m);
    }

    bool is_null(GUESTOBJECT *p) {
#ifdef SWIGPYTHON
      if (p == Py_None) return true;
#endif
#ifdef SWIGMATLAB
      if (p == 0) return true;
#endif
      return false;
    }

#ifdef SWIGMATLAB
    Sparsity get_sparsity(const mxArray* p) {
      // Get sparsity pattern
      size_t nrow = mxGetM(p);
      size_t ncol = mxGetN(p);

      if (mxIsSparse(p)) {
        // Sparse storage in MATLAB
        mwIndex *Jc = mxGetJc(p);
        mwIndex *Ir = mxGetIr(p);

        // Store in vectors
        std::vector<int> colind(ncol+1);
        std::copy(Jc, Jc+colind.size(), colind.begin());
        std::vector<int> row(colind.back());
        std::copy(Ir, Ir+row.size(), row.begin());

        // Create pattern and return
        return Sparsity(nrow, ncol, colind, row);
      } else {
        return Sparsity::dense(nrow, ncol);
      }
    }

    size_t getNNZ(const mxArray* p) {
      // Dimensions
      size_t nrow = mxGetM(p);
      size_t ncol = mxGetN(p);
      if (mxIsSparse(p)) {
        // Sparse storage in MATLAB
        mwIndex *Jc = mxGetJc(p);
        return Jc[ncol];
      } else {
        return nrow*ncol;
      }
    }
#endif // SWIGMATLAB
  } // namespace casadi
 }

%fragment("casadi_bool", "header", fragment="casadi_aux", fragment=SWIG_AsVal_frag(bool)) {
  namespace casadi {
    bool to_ptr(GUESTOBJECT *p, bool** m) {
      // Treat Null
      if (is_null(p)) return false;

      // Standard typemaps
      if (SWIG_IsOK(SWIG_AsVal(bool)(p, m ? *m : 0))) return true;

      // No match
      return false;
    }

    GUESTOBJECT * from_ptr(const bool *a) {
#ifdef SWIGPYTHON
      return PyBool_FromLong(*a);
#elif defined(SWIGMATLAB)
      return mxCreateLogicalScalar(*a);
#else
      return 0;
#endif
    }
  } // namespace casadi
 }

%fragment("casadi_int", "header", fragment="casadi_aux", fragment=SWIG_AsVal_frag(int), fragment=SWIG_AsVal_frag(long)) {
  namespace casadi {
    bool to_ptr(GUESTOBJECT *p, int** m) {
      // Treat Null
      if (is_null(p)) return false;

      // Standard typemaps
      if (SWIG_IsOK(SWIG_AsVal(int)(p, m ? *m : 0))) return true;

#ifdef SWIGPYTHON
      // Numpy integer
      if (PyArray_IsScalar(p, Integer)) {
        int tmp = PyArray_PyIntAsInt(p);
        if (!PyErr_Occurred()) {
          if (m) **m = tmp;
          return true;
        }
        PyErr_Clear();
      }
#endif // SWIGPYTHON

      // long within int bounds
      {
        long tmp;
        if (SWIG_IsOK(SWIG_AsVal(long)(p, &tmp))) {
          // Check if within bounds
          if (tmp>=std::numeric_limits<int>::min() && tmp<=std::numeric_limits<int>::max()) {
            if (m) **m = static_cast<int>(tmp);
            return true;
          }
        }
      }

      // No match
      return false;
    }

    GUESTOBJECT * from_ptr(const int *a) {
#ifdef SWIGPYTHON
      return PyInt_FromLong(*a);
#elif defined(SWIGMATLAB)
      return mxCreateDoubleScalar(static_cast<double>(*a));
#else
      return 0;
#endif
    }
  } // namespace casadi
 }

%fragment("casadi_double", "header", fragment="casadi_aux", fragment=SWIG_AsVal_frag(double)) {
  namespace casadi {
    bool to_ptr(GUESTOBJECT *p, double** m) {
      // Treat Null
      if (is_null(p)) return false;

      // Standard typemaps
      if (SWIG_IsOK(SWIG_AsVal(double)(p, m ? *m : 0))) return true;

      // No match
      return false;
    }

    GUESTOBJECT * from_ptr(const double *a) {
#ifdef SWIGPYTHON
      return PyFloat_FromDouble(*a);
#elif defined(SWIGMATLAB)
      return mxCreateDoubleScalar(*a);
#else
      return 0;
#endif
    }
  } // namespace casadi
 }


%fragment("casadi_vector", "header", fragment="casadi_aux") {
  namespace casadi {

#ifdef SWIGMATLAB
    // MATLAB row/column vector maps to std::vector<double>
    bool to_ptr(GUESTOBJECT *p, std::vector<double> **m) {
      // Treat Null
      if (is_null(p)) return false;

      if (mxIsDouble(p) && mxGetNumberOfDimensions(p)==2
          && (mxGetM(p)<=1 || mxGetN(p)<=1)) {
        if (m) {
          double* data = static_cast<double*>(mxGetData(p));
          int n = mxGetM(p)*mxGetN(p);
          (**m).resize(n);
          std::copy(data, data+n, (**m).begin());
        }
        return true;
      }

      // No match
      return false;
    }

    bool to_ptr(GUESTOBJECT *p, std::vector<int>** m) {
      if (mxIsDouble(p) && mxGetNumberOfDimensions(p)==2
          && (mxGetM(p)<=1 || mxGetN(p)<=1)) {
        double* data = static_cast<double*>(mxGetData(p));
        int n = mxGetM(p)*mxGetN(p);

        // Check if all integers
        bool all_integers=true;
        for (int i=0; all_integers && i<n; ++i) {
          if (data[i]!=static_cast<int>(data[i])) {
            all_integers = false;
            break;
          }
        }

        // Successful conversion
        if (all_integers) {
          if (m) {
            (**m).resize(n);
            std::copy(data, data+n, (**m).begin());
          }
          return true;
        }
      }
      return false;
    }

    // Cell array
    template<typename M> bool to_ptr_cell(GUESTOBJECT *p, std::vector<M>** m) {
      // Cell arrays (only row vectors)
      if (mxGetClassID(p)==mxCELL_CLASS) {
        int nrow = mxGetM(p), ncol = mxGetN(p);
        if (nrow==1 || (nrow==0 && ncol==0)) {
          // Allocate elements
          if (m) {
            (**m).clear();
            (**m).reserve(ncol);
          }

          // Temporary
          M tmp;

          // Loop over elements
          for (int i=0; i<ncol; ++i) {
            // Get element
            mxArray* pe = mxGetCell(p, i);
            if (pe==0) return false;

            // Convert element
            M *m_i = m ? &tmp : 0;
            if (!to_ptr(pe, m_i ? &m_i : 0)) {
              return false;
            }
            if (m) (**m).push_back(*m_i);
          }
          return true;
        }
      }
      return false;
    }

    // MATLAB n-by-m char array mapped to vector of length m
    bool to_ptr(GUESTOBJECT *p, std::vector<std::string>** m) {
      if (mxIsChar(p)) {
	if (m) {
          // Get data
	  size_t nrow = mxGetM(p);
	  size_t ncol = mxGetN(p);
          mxChar *data = mxGetChars(p);

          // Allocate space for output
          (**m).resize(nrow);
          std::vector<std::string> &m_ref = **m;

          // For all strings
          for (size_t j=0; j!=nrow; ++j) {
            // Get length without trailing spaces
            size_t len = ncol;
            while (len!=0 && data[j + nrow*(len-1)]==' ') --len;

            // Check if null-terminated
            for (size_t i=0; i!=len; ++i) {
              if (data[j + nrow*i]=='\0') {
                len = i;
                break;
              }
            }

            // Create a string of the desired length
            m_ref[j] = std::string(len, ' ');

            // Get string content
            for (size_t i=0; i!=len; ++i) {
              m_ref[j][i] = data[j + nrow*i];
            }
          }
        }
	return true;
      }

      // Cell array
      if (to_ptr_cell(p, m)) return true;

      // No match
      return false;
    }
#endif // SWIGMATLAB

    template<typename M> bool to_ptr(GUESTOBJECT *p, std::vector<M>** m) {
      // Treat Null
      if (is_null(p)) return false;
#ifdef SWIGPYTHON
      // 1D numpy array
      if (is_array(p) && array_numdims(p)==1 && array_type(p)!=NPY_OBJECT && array_is_native(p)) {
        int sz = array_size(p,0);

        // Make sure we have a contigous array with int datatype
        int array_is_new_object;
        PyArrayObject* array;

        // Trying NPY_INT
        if (assign_vector<int, M>(0, 0, 0)) {
          array = obj_to_array_contiguous_allow_conversion(p, NPY_INT, &array_is_new_object);
          if (array) {
            int *d = reinterpret_cast<int*>(array_data(array));
            int flag = assign_vector(d, sz, m);
            if (array_is_new_object) Py_DECREF(array);
            return flag;
          }
        }

        // Trying NPY_LONG
        if (assign_vector<long, M>(0, 0, 0)) {
          array = obj_to_array_contiguous_allow_conversion(p, NPY_LONG, &array_is_new_object);
          if (array) {
            long* d= reinterpret_cast<long*>(array_data(array));
            int flag = assign_vector(d, sz, m);
            if (array_is_new_object) Py_DECREF(array);
            return flag;
          }
        }

        // Trying NPY_DOUBLE
        if (assign_vector<double, M>(0, 0, 0)) {
          array = obj_to_array_contiguous_allow_conversion(p, NPY_DOUBLE, &array_is_new_object);
          if (array) {
            double* d= reinterpret_cast<double*>(array_data(array));
            int flag = assign_vector(d, sz, m);
            if (array_is_new_object) Py_DECREF(array);
            return flag;
          }
        }

        // No match
        return false;
      }
      // Python sequence
      if (PyList_Check(p) || PyTuple_Check(p)) {

        // Iterator to the sequence
        PyObject *it = PyObject_GetIter(p);
        if (!it) {
          PyErr_Clear();
          return false;
        }

        // Get size
        Py_ssize_t sz = PySequence_Size(p);
        if (sz==-1) {
          PyErr_Clear();
          return false;
        }

        // Allocate elements
        if (m) {
          (**m).clear();
          (**m).reserve(sz);
        }

        // Temporary
        M tmp;

        // Iterate over sequence
        for (Py_ssize_t i=0; i!=sz; ++i) {
          PyObject *pe=PyIter_Next(it);
          // Convert element
          M *m_i = m ? &tmp : 0;
          if (!to_ptr(pe, m_i ? &m_i : 0)) {
            // Failure
            Py_DECREF(pe);
            Py_DECREF(it);
            return false;
          }
          if (m) (**m).push_back(*m_i);
          Py_DECREF(pe);
        }
        Py_DECREF(it);
        return true;
      }
#endif // SWIGPYTHON
#ifdef SWIGMATLAB
      // Cell array
      if (to_ptr_cell(p, m)) return true;
#endif // SWIGMATLAB
      // No match
      return false;
    }

#ifdef SWIGMATLAB
    GUESTOBJECT* from_ptr(const std::vector<double> *a) {
      mxArray* ret = mxCreateDoubleMatrix(1, a->size(), mxREAL);
      std::copy(a->begin(), a->end(), static_cast<double*>(mxGetData(ret)));
      return ret;
    }
    GUESTOBJECT* from_ptr(const std::vector<int> *a) {
      mxArray* ret = mxCreateDoubleMatrix(1, a->size(), mxREAL);
      std::copy(a->begin(), a->end(), static_cast<double*>(mxGetData(ret)));
      return ret;
    }
    GUESTOBJECT* from_ptr(const std::vector<std::string> *a) {
      // Collect arguments as char arrays
      std::vector<const char*> str(a->size());
      for (size_t i=0; i<str.size(); ++i) str[i] = (*a)[i].c_str();

      // std::vector<string> maps to MATLAB char array with multiple columns
      return mxCreateCharMatrixFromStrings(str.size(), str.empty() ? 0 : &str[0]);
    }
#endif // SWIGMATLAB

    template<typename M> GUESTOBJECT* from_ptr(const std::vector<M> *a) {
#ifdef SWIGPYTHON
      // std::vector maps to Python list
      PyObject* ret = PyList_New(a->size());
      if (!ret) return 0;
      for (int k=0; k<a->size(); ++k) {
        PyObject* el = from_ref(a->at(k));
        if (!el) {
          Py_DECREF(ret);
          return 0;
        }
        PyList_SetItem(ret, k, el);
      }
      return ret;
#elif defined(SWIGMATLAB)
      // std::vector maps to MATLAB cell array
      mxArray* ret = mxCreateCellMatrix(1, a->size());
      if (!ret) return 0;
      for (int k=0; k<a->size(); ++k) {
        mxArray* el = from_ref(a->at(k));
        if (!el) return 0;
        mxSetCell(ret, k, el);
      }
      return ret;
#else
      return 0;
#endif
    }
  } // namespace casadi
}

%fragment("casadi_function", "header", fragment="casadi_aux") {
  namespace casadi {
    bool to_ptr(GUESTOBJECT *p, Function** m) {
      // Treat Null
      if (is_null(p)) return false;

      // GenericType already?
      if (SWIG_IsOK(SWIG_ConvertPtr(p, reinterpret_cast<void**>(m),
                                    $descriptor(casadi::Function*), 0))) {
        return true;
      }

      // No match
      return false;
    }

    GUESTOBJECT* from_ptr(const Function *a) {
      return SWIG_NewPointerObj(new Function(*a), $descriptor(casadi::Function *), SWIG_POINTER_OWN);
    }
  } // namespace casadi
}

%fragment("casadi_generictype", "header", fragment="casadi_aux") {
  namespace casadi {
    bool to_ptr(GUESTOBJECT *p, GenericType** m) {
#ifdef SWIGPYTHON
      if (p==Py_None) {
        if (m) **m=GenericType();
        return true;
      }
#endif // SWIGPYTHON

      // Treat Null
      if (is_null(p)) return false;

      // GenericType already?
      if (SWIG_IsOK(SWIG_ConvertPtr(p, reinterpret_cast<void**>(m),
                                    $descriptor(casadi::GenericType*), 0))) {
        return true;
      }

      // Try to convert to different types
      if (to_generic<int>(p, m)
          || to_generic<double>(p, m)
          || to_generic<std::string>(p, m)
          || to_generic<std::vector<int> >(p, m)
          || to_generic<std::vector<double> >(p, m)
          || to_generic<std::vector<std::string> >(p, m)
          || to_generic<std::vector<std::vector<int> > >(p, m)
          || to_generic<casadi::Function>(p, m)
          || to_generic<casadi::GenericType::Dict>(p, m)) {
        return true;
      }

      // Check if it can be converted to boolean (last as e.g. can be converted to boolean)
      if (to_generic<bool>(p, m)) return true;

      // No match
      return false;
    }

    GUESTOBJECT * from_ptr(const GenericType *a) {
      switch (a->getType()) {
      case OT_BOOL: return from_tmp(a->as_bool());
      case OT_INT: return from_tmp(a->as_int());
      case OT_DOUBLE: return from_tmp(a->as_double());
      case OT_STRING: return from_tmp(a->as_string());
      case OT_INTVECTOR: return from_tmp(a->as_int_vector());
      case OT_INTVECTORVECTOR: return from_tmp(a->as_int_vector_vector());
      case OT_DOUBLEVECTOR: return from_tmp(a->as_double_vector());
      case OT_STRINGVECTOR: return from_tmp(a->as_string_vector());
      case OT_DICT: return from_tmp(a->as_dict());
      case OT_FUNCTION: return from_tmp(a->as_function());
#ifdef SWIGPYTHON
      case OT_NULL: return Py_None;
#endif // SWIGPYTHON
      default: return 0;
      }
    }
  } // namespace casadi
}

%fragment("casadi_string", "header", fragment="casadi_aux") {
  namespace casadi {
    bool to_ptr(GUESTOBJECT *p, std::string** m) {
      // Treat Null
      if (is_null(p)) return false;

      // String already?
      if (SWIG_IsOK(SWIG_ConvertPtr(p, reinterpret_cast<void**>(m),
                                    $descriptor(std::string*), 0))) {
        return true;
      }

#ifdef SWIGPYTHON
      if (PyString_Check(p) || PyUnicode_Check(p)) {
        if (m) (*m)->clear();
        char* my_char = SWIG_Python_str_AsChar(p);
        if (m) (*m)->append(my_char);
        SWIG_Python_str_DelForPy3(my_char);
        return true;
      }
#endif // SWIGPYTHON
#ifdef SWIGMATLAB
      if (mxIsChar(p) && mxGetM(p)==1) {
	if (m) {
	  size_t len=mxGetN(p);
	  std::vector<char> s(len+1);
	  if (mxGetString(p, &s[0], (len+1)*sizeof(char))) return false;
	  **m = std::string(&s[0], len);
        }
	return true;
      }
#endif // SWIGMATLAB

      // No match
      return false;
    }

    GUESTOBJECT* from_ptr(const std::string *a) {
#ifdef SWIGPYTHON
      return PyString_FromString(a->c_str());
#elif defined(SWIGMATLAB)
      return mxCreateString(a->c_str());
#else
      return 0;
#endif
    }
  } // namespace casadi
}

%fragment("casadi_slice", "header", fragment="casadi_aux") {
  namespace casadi {
    bool to_ptr(GUESTOBJECT *p, Slice** m) {
      // Treat Null
      if (is_null(p)) return false;

      // Slice already?
      if (SWIG_IsOK(SWIG_ConvertPtr(p, reinterpret_cast<void**>(m),
                                    $descriptor(casadi::Slice*), 0))) {
        return true;
      }

#ifdef SWIGPYTHON

      // Python int
      if (PyInt_Check(p)) {
        if (m) {
          (**m).start = PyInt_AsLong(p);
          (**m).stop = (**m).start+1;
          if ((**m).stop==0) (**m).stop = std::numeric_limits<int>::max();
        }
        return true;
      }
      // Python slice
      if (PySlice_Check(p)) {
        PySliceObject *r = (PySliceObject*)(p);
        if (m) {
          (**m).start = (r->start == Py_None || PyNumber_AsSsize_t(r->start, NULL) <= std::numeric_limits<int>::min())
            ? std::numeric_limits<int>::min() : PyInt_AsLong(r->start);
          (**m).stop  = (r->stop ==Py_None || PyNumber_AsSsize_t(r->stop, NULL)>= std::numeric_limits<int>::max())
            ? std::numeric_limits<int>::max() : PyInt_AsLong(r->stop);
          if(r->step !=Py_None) (**m).step  = PyInt_AsLong(r->step);
        }
        return true;
      }
#endif // SWIGPYTHON

      // No match
      return false;
    }

    GUESTOBJECT* from_ptr(const Slice *a) {
      return SWIG_NewPointerObj(new Slice(*a), $descriptor(casadi::Slice *), SWIG_POINTER_OWN);
    }

  } // namespace casadi
}

%fragment("casadi_map", "header", fragment="casadi_aux") {
  namespace casadi {
    template<typename M> bool to_ptr(GUESTOBJECT *p, std::map<std::string, M>** m) {
#ifdef SWIGPYTHON
      if (PyDict_Check(p)) {
        PyObject *key, *value;
        Py_ssize_t pos = 0;
        while (PyDict_Next(p, &pos, &key, &value)) {
          if (!(PyString_Check(key) || PyUnicode_Check(key))) return false;
          if (m) {
            char* c_key = SWIG_Python_str_AsChar(key);
            M *v=&(**m)[std::string(c_key)], *v2=v;
            SWIG_Python_str_DelForPy3(c_key);
            if (!casadi::to_ptr(value, &v)) return false;
            if (v!=v2) *v2=*v; // if only pointer changed
          } else {
            if (!casadi::to_ptr(value, static_cast<M**>(0))) return false;
          }
        }
        return true;
      }
#elif defined(SWIGMATLAB)
      if (mxIsStruct(p) && mxGetM(p)==1 && mxGetN(p)==1) {
	int len = mxGetNumberOfFields(p);
	for (int k=0; k<len; ++k) {
	  mxArray *value = mxGetFieldByNumber(p, 0, k);
          if (m) {
	    M *v=&(**m)[std::string(mxGetFieldNameByNumber(p, k))], *v2=v;
            if (!casadi::to_ptr(value, &v)) return false;
            if (v!=v2) *v2=*v; // if only pointer changed
	  } else {
            if (!casadi::to_ptr(value, static_cast<M**>(0))) return false;
	  }
	}
        return true;
      }
#endif
      return false;
    }

    template<typename M> GUESTOBJECT* from_ptr(const std::map<std::string, M> *a) {
#ifdef SWIGPYTHON
      PyObject *p = PyDict_New();
      for (typename std::map<std::string, M>::const_iterator it=a->begin(); it!=a->end(); ++it) {
        PyObject * e = from_ptr(&it->second);
        if (!e) {
          Py_DECREF(p);
          return 0;
        }
        PyDict_SetItemString(p, it->first.c_str(), e);
        Py_DECREF(e);
      }
      return p;
#elif defined(SWIGMATLAB)
      // Get vectors of the field names and mxArrays
      std::vector<const char*> fieldnames;
      std::vector<mxArray*> fields;
      for (typename std::map<std::string, M>::const_iterator it=a->begin(); it!=a->end(); ++it) {
	fieldnames.push_back(it->first.c_str());
	mxArray* f = from_ptr(&it->second);
	if (!f) {
	  // Deallocate elements created up to now
	  for (int k=0; k<fields.size(); ++k) mxDestroyArray(fields[k]);
	  return 0;
	}
	fields.push_back(f);
      }

      // Create return object
      mxArray *p = mxCreateStructMatrix(1, 1, fields.size(),
					fieldnames.empty() ? 0 : &fieldnames[0]);
      for (int k=0; k<fields.size(); ++k) mxSetFieldByNumber(p, 0, k, fields[k]);
      return p;
#else
      return 0;
#endif
    }
  } // namespace casadi
}

%fragment("casadi_pair", "header", fragment="casadi_aux") {
  namespace casadi {
#ifdef SWIGMATLAB
    bool to_ptr(GUESTOBJECT *p, std::pair<int, int>** m) {
      // (int,int) mapped to 2-by-1 double matrix
      if (mxIsDouble(p) && mxGetNumberOfDimensions(p)==2 && !mxIsSparse(p)
          && mxGetM(p)==1 && mxGetN(p)==2) {
        double* data = static_cast<double*>(mxGetData(p));
        int first = static_cast<int>(data[0]);
        int second = static_cast<int>(data[1]);
        if (data[0]==first && data[1]==second) {
          if (m) **m = std::make_pair(first, second);
          return true;
        } else {
          return false;
        }
      }

      // No match
      return false;
    }
#endif // SWIGMATLAB

    template<typename M1, typename M2> bool to_ptr(GUESTOBJECT *p, std::pair<M1, M2>** m) {
#ifdef SWIGPYTHON
      if (PyTuple_Check(p) && PyTuple_Size(p)==2) {
        PyObject *p_first = PyTuple_GetItem(p, 0);
        PyObject *p_second = PyTuple_GetItem(p, 1);
	return to_val(p_first, m ? &(**m).first : 0)
	  && to_val(p_second, m ? &(**m).second : 0);
      }
#elif defined(SWIGMATLAB)
      // Other overloads mapped to 2-by-1 cell array
      if (mxGetClassID(p)==mxCELL_CLASS && mxGetM(p)==1 && mxGetN(p)==2) {
        mxArray *p_first = mxGetCell(p, 0);
        mxArray *p_second = mxGetCell(p, 1);
        return to_val(p_first, m ? &(**m).first : 0)
          && to_val(p_second, m ? &(**m).second : 0);
      }
#endif
      // No match
      return false;
    }

#ifdef SWIGMATLAB
    GUESTOBJECT* from_ptr(const std::pair<int, int>* a) {
      // (int,int) mapped to 2-by-1 double matrix
      mxArray* ret = mxCreateDoubleMatrix(1, 2, mxREAL);
      double* data = static_cast<double*>(mxGetData(ret));
      data[0] = a->first;
      data[1] = a->second;
      return ret;
    }
#endif // SWIGMATLAB

    template<typename M1, typename M2> GUESTOBJECT* from_ptr(const std::pair<M1, M2>* a) {
#ifdef SWIGPYTHON
      PyObject* ret = PyTuple_New(2);
      PyTuple_SetItem(ret, 0, from_ref(a->first));
      PyTuple_SetItem(ret, 1, from_ref(a->second));
      return ret;
#elif defined(SWIGMATLAB)
      // Other overloads mapped to 2-by-1 cell array
      mxArray* ret = mxCreateCellMatrix(1, 2);
      mxSetCell(ret, 0, from_ref(a->first));
      mxSetCell(ret, 1, from_ref(a->second));
      return ret;
#else
      return 0;
#endif // SWIGPYTHON
    }
  } // namespace casadi
 }

%fragment("casadi_sx", "header", fragment="casadi_aux") {
  namespace casadi {
    bool to_ptr(GUESTOBJECT *p, SX** m) {
      // Treat Null
      if (is_null(p)) return false;

      // SX already?
      if (SWIG_IsOK(SWIG_ConvertPtr(p, reinterpret_cast<void**>(m),
                                    $descriptor(casadi::Matrix<casadi::SXElem>*), 0))) {
        return true;
      }

      // Object is an DM
      {
        // Pointer to object
        DM *m2;
        if (SWIG_IsOK(SWIG_ConvertPtr(p, reinterpret_cast<void**>(&m2),
                                      $descriptor(casadi::Matrix<double>*), 0))) {
          if (m) **m=*m2;
          return true;
        }
      }

      // Object is an IM
      {
        // Pointer to object
        IM *m2;
        if (SWIG_IsOK(SWIG_ConvertPtr(p, reinterpret_cast<void**>(&m2),
                                      $descriptor(casadi::Matrix<int>*), 0))) {
          if (m) **m=*m2;
          return true;
        }
      }

      // Object is a sparsity pattern
      {
        Sparsity *m2;
        if (SWIG_IsOK(SWIG_ConvertPtr(p, reinterpret_cast<void**>(&m2),
                                      $descriptor(casadi::Sparsity*), 0))) {
          if (m) **m=SX::ones(*m2);
          return true;
        }
      }

      // Double scalar
      {
        double tmp;
        if (to_val(p, &tmp)) {
          if (m) **m=tmp;
          return true;
        }
      }

      // Integer scalar
      {
        int tmp;
        if (to_val(p, &tmp)) {
          if (m) **m=tmp;
          return true;
        }
      }

      // Try first converting to a temporary DM
      {
        DM tmp, *mt=&tmp;
        if(casadi::to_ptr(p, m ? &mt : 0)) {
          if (m) **m = *mt;
          return true;
        }
      }

#ifdef SWIGPYTHON
      // Numpy arrays will be cast to dense SX
      if (is_array(p)) {
        if (array_type(p) != NPY_OBJECT) return false;
        if (array_numdims(p)>2 || array_numdims(p)<1) return false;
        int nrows = array_size(p,0); // 1D array is cast into column vector
        int ncols  = array_numdims(p)==2 ? array_size(p,1) : 1;
        PyArrayIterObject* it = (PyArrayIterObject*)PyArray_IterNew(p);
        casadi::SX mT;
        if (m) mT = casadi::SX::zeros(ncols, nrows);
        int k=0;
        casadi::SX tmp, *tmp2;
        PyObject *pe;
        while (it->index < it->size) {
          pe = *((PyObject**) PyArray_ITER_DATA(it));
          tmp2=&tmp;
          if (!to_ptr(pe, &tmp2) || !tmp2->is_scalar()) {
            Py_DECREF(it);
            return false;
          }
          if (m) mT(k++) = *tmp2;
          PyArray_ITER_NEXT(it);
        }
        Py_DECREF(it);
        if (m) **m = mT.T();
        return true;
      }
      // Object has __SX__ method
      if (PyObject_HasAttrString(p,"__SX__")) {
        char cmd[] = "__SX__";
        PyObject *cr = PyObject_CallMethod(p, cmd, 0);
        if (!cr) return false;
        int flag = to_ptr(cr, m);
        Py_DECREF(cr);
        return flag;
      }
#endif // SWIGPYTHON

      // No match
      return false;
    }

    GUESTOBJECT* from_ptr(const SX *a) {
      return SWIG_NewPointerObj(new SX(*a), $descriptor(casadi::Matrix<casadi::SXElem> *), SWIG_POINTER_OWN);
    }
  } // namespace casadi
 }

%fragment("casadi_sxelem", "header", fragment="casadi_aux") {
  namespace casadi {
    bool to_ptr(GUESTOBJECT *p, SXElem** m) {
      // Treat Null
      if (is_null(p)) return false;

      // Try first converting to a temporary SX
      {
        SX tmp, *mt=&tmp;
        if(casadi::to_ptr(p, m ? &mt : 0)) {
          if (m && !mt->is_scalar()) return false;
          if (m) **m = mt->scalar();
          return true;
        }
      }

      // No match
      return false;
    }

    GUESTOBJECT* from_ptr(const SXElem *a) {
      return from_ref(SX(*a));
    }
  } // namespace casadi
 }

%fragment("casadi_mx", "header", fragment="casadi_decl") {
  namespace casadi {
    bool to_ptr(GUESTOBJECT *p, MX** m) {
      // Treat Null
      if (is_null(p)) return false;

      // MX already?
      if (SWIG_IsOK(SWIG_ConvertPtr(p, reinterpret_cast<void**>(m),
                                    $descriptor(casadi::MX*), 0))) {
        return true;
      }

      // Object is an DM
      {
        // Pointer to object
        DM *m2;
        if (SWIG_IsOK(SWIG_ConvertPtr(p, reinterpret_cast<void**>(&m2),
                                      $descriptor(casadi::Matrix<double>*), 0))) {
          if (m) **m=*m2;
          return true;
        }
      }

      // Object is a sparsity pattern
      {
        Sparsity *m2;
        if (SWIG_IsOK(SWIG_ConvertPtr(p, reinterpret_cast<void**>(&m2),
                                      $descriptor(casadi::Sparsity*), 0))) {
          if (m) **m=MX::ones(*m2);
          return true;
        }
      }

      // Try first converting to a temporary DM
      {
        DM tmp, *mt=&tmp;
        if(casadi::to_ptr(p, m ? &mt : 0)) {
          if (m) **m = *mt;
          return true;
        }
      }

#ifdef SWIGPYTHON
      if (PyObject_HasAttrString(p,"__MX__")) {
        char cmd[] = "__MX__";
        PyObject *cr = PyObject_CallMethod(p, cmd, 0);
        if (!cr) return false;
        int flag = to_ptr(cr, m);
        Py_DECREF(cr);
        return flag;
      }
#endif // SWIGPYTHON

      // No match
      return false;
    }

    GUESTOBJECT* from_ptr(const MX *a) {
      return SWIG_NewPointerObj(new MX(*a), $descriptor(casadi::MX*), SWIG_POINTER_OWN);
    }
  } // namespace casadi
 }

%fragment("casadi_dmatrix", "header", fragment="casadi_aux") {
  namespace casadi {
#ifdef SWIGPYTHON
    /** Check PyObjects by class name */
    bool PyObjectHasClassName(PyObject* p, const char * name) {
      PyObject * classo = PyObject_GetAttrString( p, "__class__");
      PyObject * classname = PyObject_GetAttrString( classo, "__name__");

      char* c_classname = SWIG_Python_str_AsChar(classname);
      bool ret = strcmp(c_classname, name)==0;

      Py_DECREF(classo);Py_DECREF(classname);
      SWIG_Python_str_DelForPy3(c_classname);
      return ret;
    }
#endif // SWIGPYTHON

    bool to_ptr(GUESTOBJECT *p, DM** m) {
      // Treat Null
      if (is_null(p)) return false;

      // DM already?
      if (SWIG_IsOK(SWIG_ConvertPtr(p, reinterpret_cast<void**>(m),
                                    $descriptor(casadi::Matrix<double>*), 0))) {
        return true;
      }

      // Object is an IM
      {
        // Pointer to object
        IM *m2;
        if (SWIG_IsOK(SWIG_ConvertPtr(p, reinterpret_cast<void**>(&m2),
                                      $descriptor(casadi::Matrix<int>*), 0))) {
          if (m) **m=*m2;
          return true;
        }
      }

      // Object is a sparsity pattern
      {
        Sparsity *m2;
        if (SWIG_IsOK(SWIG_ConvertPtr(p, reinterpret_cast<void**>(&m2),
                                      $descriptor(casadi::Sparsity*), 0))) {
          if (m) **m=DM::ones(*m2);
          return true;
        }
      }

      // Double scalar
      {
        double tmp;
        if (to_val(p, &tmp)) {
          if (m) **m=tmp;
          return true;
        }
      }

      // Integer scalar
      {
        int tmp;
        if (to_val(p, &tmp)) {
          if (m) **m=tmp;
          return true;
        }
      }

#ifdef SWIGPYTHON
      // Object has __DM__ method
      if (PyObject_HasAttrString(p,"__DM__")) {
        char name[] = "__DM__";
        PyObject *cr = PyObject_CallMethod(p, name, 0);
        if (!cr) return false;
        int result = to_val(cr, m ? *m : 0);
        Py_DECREF(cr);
        return result;
      }
      // Numpy arrays will be cast to dense Matrix<double>
      if (is_array(p)) {
        int array_is_new_object;
        PyArrayObject* array = obj_to_array_contiguous_allow_conversion(p, NPY_DOUBLE, &array_is_new_object);
        if (!array) return false;
        int nrow, ncol;
        switch (array_numdims(p)) {
        case 0:
          // Scalar
          nrow=ncol=1;
          break;
        case 1:
          // Vector
          nrow=array_size(p, 0);
          ncol=1;
          break;
        case 2:
          // Matrix
          nrow=array_size(p, 0);
          ncol=array_size(p, 1);
          break;
        default:
          // More than two dimension unsupported
          if (array_is_new_object) Py_DECREF(array);
          return false;
        }
        if (m) {
          **m = casadi::Matrix<double>::zeros(nrow, ncol);
          auto it=(**m)->begin();
          double* d = reinterpret_cast<double*>(array_data(array));
          for (int cc=0; cc<ncol; ++cc) {
            for (int rr=0; rr<nrow; ++rr) {
              *it++ = d[cc+rr*ncol];
            }
          }
        }

        // Free memory
        if (array_is_new_object) Py_DECREF(array);
        return true;
      }

      // scipy's csc_matrix will be cast to sparse DM
      if(PyObjectHasClassName(p, "csc_matrix")) {

        // Get the dimensions of the csc_matrix
        PyObject * shape = PyObject_GetAttrString( p, "shape"); // need's to be decref'ed
        if (!shape) return false;
        if(!PyTuple_Check(shape) || PyTuple_Size(shape)!=2) {
          Py_DECREF(shape);
          return false;
        }
        int nrows=PyInt_AsLong(PyTuple_GetItem(shape,0));
        int ncols=PyInt_AsLong(PyTuple_GetItem(shape,1));
        Py_DECREF(shape);

        bool ret= false;

        PyObject * narray=0;
        PyObject * row=0;
        PyObject * colind=0;
        PyArrayObject* array=0;
        PyArrayObject* array_row=0;
        PyArrayObject* array_colind=0;

        int array_is_new_object=0;
        int row_is_new_object=0;
        int colind_is_new_object=0;

        // Fetch data
        narray=PyObject_GetAttrString( p, "data"); // need's to be decref'ed
        if (!narray || !is_array(narray) || array_numdims(narray)!=1) goto cleanup;
        array = obj_to_array_contiguous_allow_conversion(narray,NPY_DOUBLE,&array_is_new_object);
        if (!array) goto cleanup;

        // Construct the 'row' vector needed for initialising the correct sparsity
        row = PyObject_GetAttrString(p,"indices"); // need's to be decref'ed
        if (!row || !is_array(row) || array_numdims(row)!=1) goto cleanup;
        array_row = obj_to_array_contiguous_allow_conversion(row,NPY_INT,&row_is_new_object);
        if (!array_row) goto cleanup;

        // Construct the 'colind' vector needed for initialising the correct sparsity
        colind = PyObject_GetAttrString(p,"indptr"); // need's to be decref'ed
        if (!colind || !is_array(colind) || array_numdims(colind)!=1) goto cleanup;
        array_colind = obj_to_array_contiguous_allow_conversion(colind,NPY_INT,&colind_is_new_object);
        if (!array_colind) goto cleanup;
        {
          int size=array_size(array,0); // number on non-zeros
          double* d=(double*) array_data(array);
          std::vector<double> v(d,d+size);

          int* rowd=(int*) array_data(array_row);
          std::vector<int> rowv(rowd,rowd+size);

          int* colindd=(int*) array_data(array_colind);
          std::vector<int> colindv(colindd,colindd+(ncols+1));

          if (m) **m = casadi::Matrix<double>(casadi::Sparsity(nrows,ncols,colindv,rowv), v, false);

          ret = true;
        }

      cleanup: // yes that's right; goto.
        // Rather that than a pyramid of conditional memory-deallocation
        // TODO(jaeandersson): Create a helper struct and put the below in the destructor
        if (array_is_new_object && array) Py_DECREF(array);
        if (narray) Py_DECREF(narray);
        if (row_is_new_object && array_row) Py_DECREF(array_row);
        if (row) Py_DECREF(row);
        if (colind_is_new_object && array_colind) Py_DECREF(array_colind);
        if (colind) Py_DECREF(colind);
        return ret;
      }
      if(PyObject_HasAttrString(p,"tocsc")) {
        char name[] = "tocsc";
        PyObject *cr = PyObject_CallMethod(p, name,0);
        if (!cr) return false;
        int result = to_val(cr, m ? *m : 0);
        Py_DECREF(cr);
        return result;
      }

      {
        std::vector <double> t;
        int res = to_val(p, &t);
        if (t.size()>0) {
          if (m) **m = casadi::Matrix<double>(t);
        } else {
          if (m) **m = casadi::Matrix<double>(0,0);
        }
        return res;
      }
#endif // SWIGPYTHON
#ifdef SWIGMATLAB
      // MATLAB double matrix (sparse or dense)
      if (mxIsDouble(p) && mxGetNumberOfDimensions(p)==2) {
        if (m) {
          **m = casadi::DM(get_sparsity(p));
          double* data = static_cast<double*>(mxGetData(p));
          casadi_copy(data, (*m)->nnz(), (*m)->ptr());
        }
        return true;
      }
#endif // SWIGMATLAB

      // First convert to IM
      if (can_convert<IM>(p)) {
        IM tmp;
        if (to_val(p, &tmp)) {
          if (m) **m=tmp;
          return true;
        }
      }

      // No match
      return false;
    }

    GUESTOBJECT* from_ptr(const DM *a) {
      return SWIG_NewPointerObj(new DM(*a), $descriptor(casadi::Matrix<double>*), SWIG_POINTER_OWN);
    }
  } // namespace casadi
}

%fragment("casadi_sparsity", "header", fragment="casadi_aux") {
  namespace casadi {
    bool to_ptr(GUESTOBJECT *p, Sparsity** m) {
      // Treat Null
      if (is_null(p)) return false;

      // Sparsity already?
      if (SWIG_IsOK(SWIG_ConvertPtr(p, reinterpret_cast<void**>(m),
                                    $descriptor(casadi::Sparsity*), 0))) {
        return true;
      }

      // No match
      return false;
    }

    GUESTOBJECT* from_ptr(const Sparsity *a) {
      return SWIG_NewPointerObj(new Sparsity(*a), $descriptor(casadi::Sparsity*), SWIG_POINTER_OWN);
    }
  } // namespace casadi
}

%fragment("casadi_imatrix", "header", fragment="casadi_aux", fragment=SWIG_AsVal_frag(int)) {
  namespace casadi {
    bool to_ptr(GUESTOBJECT *p, IM** m) {
      // Treat Null
      if (is_null(p)) return false;

      // IM already?
      if (SWIG_IsOK(SWIG_ConvertPtr(p, reinterpret_cast<void**>(m),
                                    $descriptor(casadi::Matrix<int>*), 0))) {
        return true;
      }

      // Object is a sparsity pattern
      {
        Sparsity *m2;
        if (SWIG_IsOK(SWIG_ConvertPtr(p, reinterpret_cast<void**>(&m2),
                                      $descriptor(casadi::Sparsity*), 0))) {
          if (m) **m=IM::ones(*m2);
          return true;
        }
      }

      // First convert to integer
      {
        int tmp;
        if (to_val(p, &tmp)) {
          if (m) **m=tmp;
          return true;
        }
      }

#ifdef SWIGPYTHON
      // Numpy arrays will be cast to dense Matrix<int>
      if (is_array(p)) {
        int array_is_new_object;
        bool is_long=false;
        PyArrayObject* array = obj_to_array_contiguous_allow_conversion(p, NPY_INT, &array_is_new_object);
        if (!array) {
          // Trying NPY_LONG
          is_long=true;
          PyErr_Clear();
          array = obj_to_array_contiguous_allow_conversion(p, NPY_LONG, &array_is_new_object);
        }
        if (!array) return false;
        int nrow, ncol;
        switch (array_numdims(p)) {
        case 0:
          // Scalar
          nrow=ncol=1;
          break;
        case 1:
          // Vector
          nrow=array_size(p, 0);
          ncol=1;
          break;
        case 2:
          // Matrix
          nrow=array_size(p, 0);
          ncol=array_size(p, 1);
          break;
        default:
          // More than two dimension unsupported
          if (array_is_new_object) Py_DECREF(array);
          return false;
        }
        if (m) {
          **m = casadi::Matrix<int>::zeros(nrow, ncol);
          auto it=(**m)->begin();
          if (is_long) {
            long* d = reinterpret_cast<long*>(array_data(array));
            for (int cc=0; cc<ncol; ++cc) {
              for (int rr=0; rr<nrow; ++rr) {
                *it++ = d[cc+rr*ncol];
              }
            }
          } else {
            int* d = reinterpret_cast<int*>(array_data(array));
            for (int cc=0; cc<ncol; ++cc) {
              for (int rr=0; rr<nrow; ++rr) {
                *it++ = d[cc+rr*ncol];
              }
            }
          }
        }

        // Free memory
        if (array_is_new_object) Py_DECREF(array);
        return true;
      }

      if (PyObject_HasAttrString(p,"__IM__")) {
        char cmd[] = "__IM__";
        PyObject *cr = PyObject_CallMethod(p, cmd, 0);
        if (!cr) return false;
        int result = to_val(cr, m ? *m : 0);
        Py_DECREF(cr);
        return result;
      }

      {
        std::vector <int> t;
        int res = to_val(p, &t);
        if (m) **m = casadi::Matrix<int>(t);
        return res;
      }
      return true;
#endif // SWIGPYTHON
#ifdef SWIGMATLAB
      // In MATLAB, it is common to use floating point values to represent integers
      if (mxIsDouble(p) && mxGetNumberOfDimensions(p)==2) {
        double* data = static_cast<double*>(mxGetData(p));

        // Check if all integers
        bool all_integers=true;
        size_t sz = getNNZ(p);
        for (size_t i=0; i<sz; ++i) {
          if (data[i] != int(data[i])) {
            all_integers = false;
            break;
          }
        }

        // If successful
        if (all_integers) {
          if (m) {
            **m = casadi::IM(get_sparsity(p));
            for (size_t i=0; i<sz; ++i) {
              (**m)->at(i) = int(data[i]);
            }
          }
          return true;
        }
      }
#endif // SWIGMATLAB

      // No match
      return false;
    }

    GUESTOBJECT* from_ptr(const IM *a) {
      return SWIG_NewPointerObj(new IM(*a), $descriptor(casadi::Matrix<int>*), SWIG_POINTER_OWN);
    }
  } // namespace casadi
 }

// Collect all fragments
%fragment("casadi_all", "header", fragment="casadi_aux,casadi_bool,casadi_int,casadi_double,casadi_vector,casadi_function,casadi_generictype,casadi_string,casadi_slice,casadi_map,casadi_pair,casadi_sx,casadi_sxelem,casadi_mx,casadi_dmatrix,casadi_sparsity,casadi_imatrix") { }

#endif // SWIGXML

 // Define all input typemaps
%define %casadi_input_typemaps(xName, xPrec, xType...)
 // Pass input by value, check if matches
%typemap(typecheck, noblock=1, precedence=xPrec, fragment="casadi_all") xType {
  $1 = casadi::to_ptr($input, static_cast< xType **>(0));
 }

 // Directorout typemap; as input by value
%typemap(directorout, noblock=1, fragment="casadi_all") xType {
    if (!casadi::to_val($input, &$result)) {
      %dirout_fail(SWIG_TypeError,"$type");
    }
 }

 // Pass input by value, convert argument
%typemap(in, noblock=1, fragment="casadi_all") xType {
  if (!casadi::to_val($input, &$1)) SWIG_exception_fail(SWIG_TypeError,"Cannot convert input to " xName ".");
 }

 // Pass input by value, cleanup
%typemap(freearg, noblock=1) xType {}

 // Pass input by reference, check if matches
%typemap(typecheck, noblock=1, precedence=xPrec, fragment="casadi_all") const xType& {
  $1 = casadi::to_ptr($input, static_cast< xType **>(0));
 }

 // Pass input by reference, convert argument
%typemap(in, noblock=1, fragment="casadi_all") const xType & (xType m) {
  $1 = &m;
  if (!casadi::to_ptr($input, &$1)) SWIG_exception_fail(SWIG_TypeError,"Failed to convert input to " xName ".");
 }

 // Pass input by reference, cleanup
%typemap(freearg, noblock=1) const xType & {}
%enddef

 // Define all output typemaps
%define %casadi_output_typemaps(xName, xType...)

 // Return-by-value
%typemap(out, noblock=1, fragment="casadi_all") xType, const xType {
  if(!($result = casadi::from_ref($1))) SWIG_exception_fail(SWIG_TypeError,"Failed to convert output to " xName ".");
}

// Return a const-ref behaves like return-by-value
%typemap(out, noblock=1, fragment="casadi_all") const xType& {
  if(!($result = casadi::from_ptr($1))) SWIG_exception_fail(SWIG_TypeError,"Failed to convert output to " xName ".");
}

// Inputs marked OUTPUT are also returned by the function, ...
%typemap(argout,noblock=1,fragment="casadi_all") xType &OUTPUT {
  %append_output(casadi::from_ptr($1));
 }

// ... and the corresponding inputs are ignored
%typemap(in, noblock=1, numinputs=0) xType &OUTPUT (xType m) {
 $1 = &m;
}

 // Enable dynamic dispatch
%typemap(typecheck, noblock=1, fragment="casadi_all") xType &OUTPUT {
  $1 = casadi::to_ptr($input, static_cast< xType **>(0));
 }

// Alternative names
%apply xType &OUTPUT {xType &OUTPUT1};
%apply xType &OUTPUT {xType &OUTPUT2};
%apply xType &OUTPUT {xType &OUTPUT3};
%apply xType &OUTPUT {xType &OUTPUT4};
%apply xType &OUTPUT {xType &OUTPUT5};
%apply xType &OUTPUT {xType &OUTPUT6};

// Inputs marked INOUT are also returned by the function, ...
%typemap(argout,noblock=1,fragment="casadi_all") xType &INOUT {
  %append_output(casadi::from_ptr($1));
 }

// ... but kept as inputs
%typemap(in, noblock=1, fragment="casadi_all") xType &INOUT (xType m) {
  $1 = &m;
  if (!casadi::to_ptr($input, &$1)) SWIG_exception_fail(SWIG_TypeError,"Failed to convert input to " xName ".");
 }

 // ... also for dynamic dispatch
%typemap(typecheck, noblock=1, fragment="casadi_all") xType& INOUT {
  $1 = casadi::to_ptr($input, static_cast< xType **>(0));
 }

// No arguments need to be freed
%typemap(freearg, noblock=1) xType& INOUT {}

// Alternative names
%apply xType &INOUT {xType &INOUT1};
%apply xType &INOUT {xType &INOUT2};
%apply xType &INOUT {xType &INOUT3};
%apply xType &INOUT {xType &INOUT4};
%apply xType &INOUT {xType &INOUT5};
%apply xType &INOUT {xType &INOUT6};

%enddef

 // Define all typemaps for a template instantiation without proxy classes
%define %casadi_template(xName, xPrec, xType...)
%template() xType;
%casadi_input_typemaps(xName, xPrec, xType)
%casadi_output_typemaps(xName, %arg(xType))
%enddef

 // Define all input and ouput typemaps
%define %casadi_typemaps(xName, xPrec, xType...)
%casadi_input_typemaps(xName, xPrec, xType)
%casadi_output_typemaps(xName, xType)
%enddef

// Order in typemap matching: Lower value means will be checked first
%define PREC_GENERICTYPE 22 %enddef
%define PREC_DICT 21 %enddef
%define PREC_SPARSITY 90 %enddef
%define PREC_IVector 92 %enddef
%define PREC_IVectorVector 92 %enddef
%define PREC_VECTOR 92 %enddef
%define PREC_PAIR_SLICE_SLICE 93 %enddef
%define PREC_SLICE 94 %enddef
%define PREC_PAIR_IVector_IVector 96 %enddef
%define PREC_IM 97 %enddef
%define PREC_IMVector 98 %enddef
%define PREC_IMVectorVector 98 %enddef
%define PREC_DVector 99 %enddef
%define PREC_DM 100 %enddef
%define PREC_DMVector 101 %enddef
%define PREC_DMVectorVector 101 %enddef
%define PREC_SX 103 %enddef
%define PREC_SXVector 103 %enddef
%define PREC_SXVectorVector 103 %enddef
%define PREC_MX 104 %enddef
%define PREC_MXVector 105 %enddef
%define PREC_MXVectorVector 106 %enddef
%define PREC_CREATOR 150 %enddef
%define PREC_STRING 180 %enddef
%define PREC_FUNCTION 200 %enddef

#ifndef SWIGXML

 // std::ostream & is not typemapped to anything useful and should be ignored
 // (or possibly turned into a string output)
%typemap(in, noblock=1, numinputs=0) std::ostream &stream ""

%casadi_typemaps("str", PREC_STRING, std::string)
%casadi_template("[str]", PREC_STRING, std::vector<std::string>)
%casadi_typemaps("Sparsity", PREC_SPARSITY, casadi::Sparsity)
%casadi_template("[Sparsity]", PREC_SPARSITY, std::vector< casadi::Sparsity>)
%casadi_template("[[Sparsity]]", PREC_SPARSITY, std::vector<std::vector< casadi::Sparsity> >)
%casadi_template("str:Sparsity", PREC_SPARSITY, std::map<std::string, casadi::Sparsity >)
%casadi_template("str:[Sparsity]", PREC_SPARSITY, std::map<std::string, std::vector<casadi::Sparsity > >)
%casadi_template("(str:Sparsity,[str])", PREC_SPARSITY, std::pair<std::map<std::string, casadi::Sparsity >, std::vector<std::string> >)
%casadi_typemaps("bool", SWIG_TYPECHECK_BOOL, bool)
%casadi_template("[bool]", SWIG_TYPECHECK_BOOL, std::vector<bool>)
%casadi_template("[[bool]]", SWIG_TYPECHECK_BOOL, std::vector<std::vector<bool> >)
%casadi_typemaps("int", SWIG_TYPECHECK_INTEGER, int)
%casadi_template("(int,int)", SWIG_TYPECHECK_INTEGER, std::pair<int,int>)
%casadi_template("[int]", PREC_IVector, std::vector<int>)
%casadi_template("[[int]]", PREC_IVectorVector, std::vector<std::vector<int> >)
%casadi_typemaps("double", SWIG_TYPECHECK_DOUBLE, double)
%casadi_template("[double]", SWIG_TYPECHECK_DOUBLE, std::vector<double>)
%casadi_template("[[double]]", SWIG_TYPECHECK_DOUBLE, std::vector<std::vector<double> >)
%casadi_typemaps("SXElem", PREC_SX, casadi::SXElem)
%casadi_template("[SXElem]", PREC_SXVector, std::vector<casadi::SXElem>)
%casadi_typemaps("SX", PREC_SX, casadi::Matrix<casadi::SXElem>)
%casadi_template("[SX]", PREC_SXVector, std::vector< casadi::Matrix<casadi::SXElem> >)
%casadi_template("[[SX]]", PREC_SXVectorVector, std::vector<std::vector< casadi::Matrix<casadi::SXElem> > >)
%casadi_template("str:SX", PREC_SX, std::map<std::string, casadi::Matrix<casadi::SXElem> >)
%casadi_typemaps("MX", PREC_MX, casadi::MX)
%casadi_template("[MX]", PREC_MXVector, std::vector<casadi::MX>)
%casadi_template("[[MX]]", PREC_MXVectorVector, std::vector<std::vector<casadi::MX> >)
%casadi_template("str:MX", PREC_MX, std::map<std::string, casadi::MX>)
%casadi_typemaps("DM", PREC_DM, casadi::Matrix<double>)
%casadi_template("[DM]", PREC_DMVector, std::vector< casadi::Matrix<double> >)
%casadi_template("[[DM]]", PREC_DMVectorVector, std::vector<std::vector< casadi::Matrix<double> > >)
%casadi_template("str:DM", PREC_DM, std::map<std::string, casadi::Matrix<double> >)
%casadi_typemaps("IM", PREC_IM, casadi::Matrix<int>)
%casadi_template("[IM]", PREC_IMVector, std::vector< casadi::Matrix<int> >)
%casadi_template("[[IM]]", PREC_IMVectorVector, std::vector<std::vector< casadi::Matrix<int> > >)
%casadi_typemaps("GenericType", PREC_GENERICTYPE, casadi::GenericType)
%casadi_template("[GenericType]", PREC_GENERICTYPE, std::vector<casadi::GenericType>)
%casadi_typemaps("Slice", PREC_SLICE, casadi::Slice)
%casadi_typemaps("Function", PREC_FUNCTION, casadi::Function)
%casadi_template("[Function]", PREC_FUNCTION, std::vector<casadi::Function>)
%casadi_template("(Function,Function)", PREC_FUNCTION, std::pair<casadi::Function, casadi::Function>)
%casadi_template("Dict", PREC_DICT, std::map<std::string, casadi::GenericType>)

#endif // SWIGXML

#ifdef SWIGPYTHON
%pythoncode %{
if __name__ != "casadi.casadi":
  raise Exception("""
            CasADi is not running from its package context.

            You probably specified the wrong casadi directory.

            When setting PYTHONPATH or sys.path.append,
            take care not to add a trailing '/casadi'.

        """)
import _casadi
%}
#endif // SWIGPYTHON

// Init hooks
#ifdef SWIGPYTHON
#ifdef WITH_PYTHON_INTERRUPTS
%{
#include <pythonrun.h>
void SigIntHandler(int) {
  std::cerr << "Keyboard Interrupt" << std::endl;
  signal(SIGINT, SIG_DFL);
  kill(getpid(), SIGINT);
}
%}

%init %{
PyOS_setsig(SIGINT, SigIntHandler);
%}
#endif // WITH_PYTHON_INTERRUPTS

%pythoncode%{
try:
  from numpy import pi, inf
except:
  pass

arcsin = lambda x: _casadi.asin(x)
arccos = lambda x: _casadi.acos(x)
arctan = lambda x: _casadi.atan(x)
arctan2 = lambda x,y: _casadi.atan2(x, y)
arctanh = lambda x: _casadi.atanh(x)
arcsinh = lambda x: _casadi.asinh(x)
arccosh = lambda x: _casadi.acosh(x)
%}
#endif // SWIGPYTHON

// Strip leading casadi_ unless followed by ML
%rename("%(regex:/casadi_(?!ML)(.*)/\\1/)s") "";

%rename(row) get_row;
%rename(colind) get_colind;
%rename(sparsity) get_sparsity;
%rename(nonzeros) get_nonzeros;

// Explicit conversion to double and int
#ifdef SWIGPYTHON
%rename(__float__) operator double;
%rename(__int__) operator int;
#else
%rename(to_double) operator double;
%rename(to_int) operator int;
#endif
%rename(to_DM) operator Matrix<double>;

#ifdef SWIGPYTHON
%ignore T;

%rename(logic_and) casadi_and;
%rename(logic_or) casadi_or;
%rename(logic_not) casadi_not;
%rename(logic_all) casadi_all;
%rename(logic_any) casadi_any;
%rename(fabs) casadi_abs;
%rename(fmin) casadi_min;
%rename(fmax) casadi_max;

// Concatenations
%rename(_veccat) casadi_veccat;
%rename(_vertcat) casadi_vertcat;
%rename(_horzcat) casadi_horzcat;
%rename(_diagcat) casadi_diagcat;
%pythoncode %{
def veccat(*args): return _veccat(args)
def vertcat(*args): return _vertcat(args)
def horzcat(*args): return _horzcat(args)
def diagcat(*args): return _diagcat(args)
def vcat(args): return _vertcat(args)
def hcat(args): return _horzcat(args)
def dcat(args): return _diagcat(args)
%}

// Non-fatal errors (returning NotImplemented singleton)
%feature("python:maybecall") casadi_plus;
%feature("python:maybecall") casadi_minus;
%feature("python:maybecall") casadi_times;
%feature("python:maybecall") casadi_rdivide;
%feature("python:maybecall") casadi_lt;
%feature("python:maybecall") casadi_le;
%feature("python:maybecall") casadi_eq;
%feature("python:maybecall") casadi_ne;
%feature("python:maybecall") casadi_power;
%feature("python:maybecall") casadi_atan2;
%feature("python:maybecall") casadi_min;
%feature("python:maybecall") casadi_max;
%feature("python:maybecall") casadi_and;
%feature("python:maybecall") casadi_or;
%feature("python:maybecall") casadi_mod;
%feature("python:maybecall") casadi_copysign;
%feature("python:maybecall") casadi_constpow;
#endif // SWIGPYTHON

#ifdef SWIGMATLAB
%rename(uminus) operator-;
%rename(uplus) operator+;
%feature("varargin","1") casadi_vertcat;
%feature("varargin","1") casadi_horzcat;
%feature("varargin","1") casadi_veccat;
%feature("optionalunpack","1") size;

// Raise an error if "this" not correct
%typemap(check, noblock=1) SWIGTYPE *self %{
if (!$1) {
  SWIG_Error(SWIG_RuntimeError, "Invalid 'self' object");
  SWIG_fail;
 }
%}

// Workarounds, pending proper fix
%rename(nonzero) __nonzero__;
%rename(hash) __hash__;
#endif // SWIGMATLAB

#ifdef WITH_PYTHON3
%rename(__bool__) __nonzero__;
#endif

#ifdef SWIGPYTHON

%pythoncode %{
class NZproxy:
  def __init__(self,matrix):
    self.matrix = matrix

  def __getitem__(self,s):
    return self.matrix.get_nz(False, s)

  def __setitem__(self,s,val):
    return self.matrix.set_nz(val, False, s)

  def __len__(self):
    return self.matrix.nnz()
%}

%define %matrix_helpers(Type)
%pythoncode %{
    @property
    def shape(self):
        return (self.size1(),self.size2())

    def reshape(self,arg):
        return _casadi.reshape(self,arg)

    @property
    def T(self):
        return _casadi.transpose(self)

    def __getitem__(self, s):
          if isinstance(s, tuple) and len(s)==2:
            if s[1] is None: raise TypeError("Cannot slice with None")
            return self.get(False, s[0], s[1])
          return self.get(False, s)

    def __setitem__(self,s,val):
          if isinstance(s,tuple) and len(s)==2:
            return self.set(val, False, s[0], s[1])
          return self.set(val, False, s)

    @property
    def nz(self):
      return NZproxy(self)

%}
%enddef

%define %python_array_wrappers(arraypriority)
%pythoncode %{

  __array_priority__ = arraypriority

  def __array_wrap__(self,out_arr,context=None):
    if context is None:
      return out_arr
    name = context[0].__name__
    args = list(context[1])

    if len(context[1])==3:
      raise Exception("Error with %s. Looks like you are using an assignment operator, such as 'a+=b' where 'a' is a numpy type. This is not supported, and cannot be supported without changing numpy." % name)

    if "vectorized" in name:
        name = name[:-len(" (vectorized)")]

    conversion = {"multiply": "mul", "divide": "div", "true_divide": "div", "subtract":"sub","power":"pow","greater_equal":"ge","less_equal": "le", "less": "lt", "greater": "gt"}
    if name in conversion:
      name = conversion[name]
    if len(context[1])==2 and context[1][1] is self and not(context[1][0] is self):
      name = 'r' + name
      args.reverse()
    if not(hasattr(self,name)) or ('mul' in name):
      name = '__' + name + '__'
    fun=getattr(self, name)
    return fun(*args[1:])


  def __array__(self,*args,**kwargs):
    import numpy as n
    if len(args) > 1 and isinstance(args[1],tuple) and isinstance(args[1][0],n.ufunc) and isinstance(args[1][0],n.ufunc) and len(args[1])>1 and args[1][0].nin==len(args[1][1]):
      if len(args[1][1])==3:
        raise Exception("Error with %s. Looks like you are using an assignment operator, such as 'a+=b'. This is not supported when 'a' is a numpy type, and cannot be supported without changing numpy itself. Either upgrade a to a CasADi type first, or use 'a = a + b'. " % args[1][0].__name__)
      return n.array([n.nan])
    else:
      if hasattr(self,'__array_custom__'):
        return self.__array_custom__(*args,**kwargs)
      else:
        return self.full()

%}
%enddef
#endif // SWIGPYTHON

#ifdef SWIGXML
%define %matrix_helpers(Type)
%enddef
#endif

#ifdef SWIGMATLAB
%{
  namespace casadi {
    /// Helper function: Convert ':' to Slice
    inline Slice char2Slice(char ch) {
      casadi_assert(ch==':');
      return Slice();
    }
  } // namespace casadi
%}

%define %matrix_helpers(Type)
    // Get a submatrix (index-1)
    const Type paren(char rr) const {
      casadi_assert(rr==':');
      return vec(*$self);
    }
    const Type paren(const Matrix<int>& rr) const {
      Type m;
      $self->get(m, true, rr);
      return m;
    }
    const Type paren(const Sparsity& sp) const {
      Type m;
      $self->get(m, true, sp);
      return m;
    }
    const Type paren(char rr, char cc) const {
      Type m;
      $self->get(m, true, casadi::char2Slice(rr), casadi::char2Slice(cc));
      return m;
    }
    const Type paren(char rr, const Matrix<int>& cc) const {
      Type m;
      $self->get(m, true, casadi::char2Slice(rr), cc);
      return m;
    }
    const Type paren(const Matrix<int>& rr, char cc) const {
      Type m;
      $self->get(m, true, rr, casadi::char2Slice(cc));
      return m;
    }
    const Type paren(const Matrix<int>& rr, const Matrix<int>& cc) const {
      Type m;
      $self->get(m, true, rr, cc);
      return m;
    }

    // Set a submatrix (index-1)
    void paren_asgn(const Type& m, char rr) { $self->set(m, true, casadi::char2Slice(rr));}
    void paren_asgn(const Type& m, const Matrix<int>& rr) { $self->set(m, true, rr);}
    void paren_asgn(const Type& m, const Sparsity& sp) { $self->set(m, true, sp);}
    void paren_asgn(const Type& m, char rr, char cc) { $self->set(m, true, casadi::char2Slice(rr), casadi::char2Slice(cc));}
    void paren_asgn(const Type& m, char rr, const Matrix<int>& cc) { $self->set(m, true, casadi::char2Slice(rr), cc);}
    void paren_asgn(const Type& m, const Matrix<int>& rr, char cc) { $self->set(m, true, rr, casadi::char2Slice(cc));}
    void paren_asgn(const Type& m, const Matrix<int>& rr, const Matrix<int>& cc) { $self->set(m, true, rr, cc);}

    // Get nonzeros (index-1)
    const Type brace(char rr) const { Type m; $self->get_nz(m, true, casadi::char2Slice(rr)); return m;}
    const Type brace(const Matrix<int>& rr) const { Type m; $self->get_nz(m, true, rr); return m;}

    // Set nonzeros (index-1)
    void setbrace(const Type& m, char rr) { $self->set_nz(m, true, casadi::char2Slice(rr));}
    void setbrace(const Type& m, const Matrix<int>& rr) { $self->set_nz(m, true, rr);}

    // 'end' function (needed for end syntax in MATLAB)
    inline int end(int i, int n) const {
      return n==1 ? $self->numel() : i==1 ? $self->size1() : $self->size2();
    }

    // Transpose using the A' syntax in addition to A.'
    Type ctranspose() const { return $self->T();}

%enddef
#endif

%include <casadi/core/printable_object.hpp>

#ifdef SWIGPYTHON
%rename(SWIG_STR) getDescription;
#endif // SWIGPYTHON

%template(PrintSharedObject) casadi::PrintableObject<casadi::SharedObject>;
%template(PrintSlice)        casadi::PrintableObject<casadi::Slice>;
%template(PrintIM)      casadi::PrintableObject<casadi::Matrix<int> >;
%template(PrintDM)      casadi::PrintableObject<casadi::Matrix<double> >;
//%template(PrintSX)           casadi::PrintableObject<casadi::Matrix<casadi::SXElem> >;
%template(PrintNlpBuilder)     casadi::PrintableObject<casadi::NlpBuilder>;
%template(PrintVariable)        casadi::PrintableObject<casadi::Variable>;
%template(PrintDaeBuilder)     casadi::PrintableObject<casadi::DaeBuilder>;

%include <casadi/core/shared_object.hpp>
%include <casadi/core/std_vector_tools.hpp>
%include <casadi/core/weak_ref.hpp>
%include <casadi/core/casadi_types.hpp>
%include <casadi/core/generic_type.hpp>
%include <casadi/core/calculus.hpp>
%include <casadi/core/sparsity_interface.hpp>

%template(SpSparsity) casadi::SparsityInterface<casadi::Sparsity>;
%include <casadi/core/sparsity.hpp>

// Logic for pickling
#ifdef SWIGPYTHON
namespace casadi{
%extend Sparsity {
  %pythoncode %{
    def __setstate__(self, state):
        if state:
          self.__init__(state["nrow"],state["ncol"],state["colind"],state["row"])
        else:
          self.__init__()

    def __getstate__(self):
        if self.is_null(): return {}
        return {"nrow": self.size1(), "ncol": self.size2(), "colind": numpy.array(self.colind(),dtype=int), "row": numpy.array(self.row(),dtype=int)}
  %}
}

} // namespace casadi
#endif // SWIGPYTHON

/* There is no reason to expose the Slice class to e.g. Python or MATLAB. Only if an interfaced language
   lacks a slice type, the type should be exposed here */
// #if !(defined(SWIGPYTHON) || defined(SWIGMATLAB))
%include <casadi/core/slice.hpp>
 //#endif

%template(SpIM)        casadi::SparsityInterface<casadi::Matrix<int> >;
%template(SpDM)        casadi::SparsityInterface<casadi::Matrix<double> >;
%template(SpSX)             casadi::SparsityInterface<casadi::Matrix<casadi::SXElem> >;
%template(SpMX)             casadi::SparsityInterface<casadi::MX>;

%include <casadi/core/generic_matrix.hpp>

%template(GenIM)        casadi::GenericMatrix<casadi::Matrix<int> >;
%template(GenDM)        casadi::GenericMatrix<casadi::Matrix<double> >;
%template(GenSX)             casadi::GenericMatrix<casadi::Matrix<casadi::SXElem> >;
%template(GenMX)             casadi::GenericMatrix<casadi::MX>;

%include <casadi/core/generic_expression.hpp>

%template(ExpIM)        casadi::GenericExpression<casadi::Matrix<int> >;
%template(ExpDM)        casadi::GenericExpression<casadi::Matrix<double> >;
%template(ExpSX)             casadi::GenericExpression<casadi::Matrix<casadi::SXElem> >;
%template(ExpMX)             casadi::GenericExpression<casadi::MX>;

// Flags to allow differentiating the wrapping by type
#define IS_GLOBAL   0x1
#define IS_MEMBER   0x10
#define IS_SPARSITY 0x100
#define IS_DMATRIX  0x1000
#define IS_IMATRIX  0x10000
#define IS_SX       0x100000
#define IS_MX       0x1000000
#define IS_DOUBLE   0x10000000

%define SPARSITY_INTERFACE_FUN_BASE(DECL, FLAG, M)
#if FLAG & IS_MEMBER

 DECL M casadi_horzcat(const std::vector< M > &v) {
  return horzcat(v);
 }
 DECL M casadi_vertcat(const std::vector< M > &v) {
 return vertcat(v);
 }
 DECL std::vector< M >
 casadi_horzsplit(const M& v, const std::vector<int>& offset) {
 return horzsplit(v, offset);
 }
 DECL std::vector< M > casadi_horzsplit(const M& v, int incr=1) {
 return horzsplit(v, incr);
 }
 DECL std::vector< M >
 casadi_vertsplit(const M& v, const std::vector<int>& offset) {
 return vertsplit(v, offset);
 }
 DECL std::vector<int >
 casadi_offset(const std::vector< M > &v, bool vert=true) {
 return offset(v, vert);
 }
 DECL std::vector< M >
 casadi_vertsplit(const M& v, int incr=1) {
 return vertsplit(v, incr);
 }
 DECL M casadi_blockcat(const std::vector< std::vector< M > > &v) {
 return blockcat(v);
 }
 DECL M casadi_blockcat(const M& A, const M& B, const M& C, const M& D) {
 return vertcat(horzcat(A, B), horzcat(C, D));
 }
 DECL std::vector< std::vector< M > >
 casadi_blocksplit(const M& x, const std::vector<int>& vert_offset,
 const std::vector<int>& horz_offset) {
 return blocksplit(x, vert_offset, horz_offset);
 }
 DECL std::vector< std::vector< M > >
 casadi_blocksplit(const M& x, int vert_incr=1, int horz_incr=1) {
 return blocksplit(x, vert_incr, horz_incr);
 }
 DECL M casadi_diagcat(const std::vector< M > &A) {
 return diagcat(A);
 }
 DECL std::vector< M >
 casadi_diagsplit(const M& x, const std::vector<int>& output_offset1,
 const std::vector<int>& output_offset2) {
 return diagsplit(x, output_offset1, output_offset2);
 }
 DECL std::vector< M >
 casadi_diagsplit(const M& x, const std::vector<int>& output_offset) {
 return diagsplit(x, output_offset);
 }
 DECL std::vector< M > casadi_diagsplit(const M& x, int incr=1) {
 return diagsplit(x, incr);
 }
 DECL std::vector< M >
 casadi_diagsplit(const M& x, int incr1, int incr2) {
 return diagsplit(x, incr1, incr2);
 }
 DECL M casadi_veccat(const std::vector< M >& x) {
 return veccat(x);
 }
 DECL M casadi_mtimes(const M& x, const M& y) {
 return mtimes(x, y);
 }
 DECL M casadi_mtimes(const std::vector< M > &args) {
 return mtimes(args);
 }
 DECL M casadi_mac(const M& X, const M& Y, const M& Z) {
 return mac(X, Y, Z);
 }
 DECL M casadi_transpose(const M& X) {
 return X.T();
 }
 DECL M casadi_vec(const M& a) {
 return vec(a);
 }
 DECL M casadi_reshape(const M& a, int nrow, int ncol) {
 return reshape(a, nrow, ncol);
 }
 DECL M casadi_reshape(const M& a, std::pair<int, int> rc) {
 return reshape(a, rc.first, rc.second);
 }
 DECL M casadi_reshape(const M& a, const Sparsity& sp) {
 return reshape(a, sp);
 }
 DECL int casadi_sprank(const M& A) {
 return sprank(A);
 }
 DECL int casadi_norm_0_mul(const M& x, const M& y) {
 return norm_0_mul(x, y);
 }
 DECL M casadi_triu(const M& a, bool includeDiagonal=true) {
 return triu(a, includeDiagonal);
 }
 DECL M casadi_tril(const M& a, bool includeDiagonal=true) {
 return tril(a, includeDiagonal);
 }
 DECL M casadi_kron(const M& a, const M& b) {
 return kron(a, b);
 }
 DECL M casadi_repmat(const M& A, int n, int m=1) {
 return repmat(A, n, m);
 }
 DECL M casadi_repmat(const M& A, const std::pair<int, int>& rc) {
 return repmat(A, rc.first, rc.second);
 }
#endif
%enddef

%define SPARSITY_INTERFACE_ALL(DECL, FLAG)
SPARSITY_INTERFACE_FUN(DECL, (FLAG | IS_SPARSITY), Sparsity)
SPARSITY_INTERFACE_FUN(DECL, (FLAG | IS_MX), MX)
SPARSITY_INTERFACE_FUN(DECL, (FLAG | IS_IMATRIX), Matrix<int>)
SPARSITY_INTERFACE_FUN(DECL, (FLAG | IS_DMATRIX), Matrix<double>)
SPARSITY_INTERFACE_FUN(DECL, (FLAG | IS_SX), Matrix<SXElem>)
%enddef

#ifdef SWIGMATLAB
  %define SPARSITY_INTERFACE_FUN(DECL, FLAG, M)
    SPARSITY_INTERFACE_FUN_BASE(DECL, FLAG, M)
    #if FLAG & IS_MEMBER
     DECL int casadi_length(const M &v) {
      return std::max(v.size1(), v.size2());
     }
    #endif
  %enddef
#else
  %define SPARSITY_INTERFACE_FUN(DECL, FLAG, M)
    SPARSITY_INTERFACE_FUN_BASE(DECL, FLAG, M)
  %enddef
#endif

%define GENERIC_MATRIX_FUN(DECL, FLAG, M)
#if FLAG & IS_MEMBER
DECL M casadi_mpower(const M& x, const M& n) {
  return mpower(x, n);
}

DECL M casadi_mrdivide(const M& x, const M& y) {
  return mrdivide(x, y);
}

DECL M casadi_mldivide(const M& x, const M& y) {
  return mldivide(x, y);
}

DECL std::vector< M > casadi_symvar(const M& x) {
  return symvar(x);
}

DECL M casadi_bilin(const M& A, const M& x, const M& y) {
  return bilin(A, x, y);
}

DECL M casadi_rank1(const M& A, const M& alpha, const M& x, const M& y) {
  return rank1(A, alpha, x, y);
}

DECL M casadi_sum_square(const M& X) {
  return sum_square(X);
}

DECL M casadi_linspace(const M& a, const M& b, int nsteps) {
  return linspace(a, b, nsteps);
}

DECL M casadi_cross(const M& a, const M& b, int dim = -1) {
  return cross(a, b, dim);
}

DECL M casadi_skew(const M& a) {
  return skew(a);
}

DECL M casadi_inv_skew(const M& a) {
  return inv_skew(a);
}

DECL M casadi_det(const M& A) {
  return det(A);
}

DECL M casadi_inv(const M& A) {
  return inv(A);
}

DECL M casadi_trace(const M& a) {
  return trace(a);
}

DECL M casadi_tril2symm(const M& a) {
  return tril2symm(a);
}

DECL M casadi_triu2symm(const M& a) {
  return triu2symm(a);
}

DECL M casadi_norm_F(const M& x) {
  return norm_F(x);
}

DECL M casadi_norm_2(const M& x) {
  return norm_2(x);
}

DECL M casadi_norm_1(const M& x) {
  return norm_1(x);
}

DECL M casadi_norm_inf(const M& x) {
  return norm_inf(x);
}

DECL M casadi_sum2(const M& x) {
  return sum2(x);
}

DECL M casadi_sum1(const M& x) {
  return sum1(x);
}

DECL M casadi_dot(const M& x, const M& y) {
  return dot(x, y);
}

DECL M casadi_nullspace(const M& A) {
  return nullspace(A);
}

DECL M casadi_polyval(const M& p, const M& x) {
  return polyval(p, x);
}

DECL M casadi_diag(const M& A) {
  return diag(A);
}

DECL M casadi_unite(const M& A, const M& B) {
  return unite(A, B);
}

DECL M casadi_densify(const M& x) {
  return densify(x);
}

DECL M casadi_project(const M& A, const Sparsity& sp, bool intersect=false) {
  return project(A, sp, intersect);
}

DECL M casadi_if_else(const M& cond, const M& if_true,
                    const M& if_false, bool short_circuit=true) {
  return if_else(cond, if_true, if_false, short_circuit);
}

DECL M casadi_conditional(const M& ind, const std::vector< M > &x,
                        const M& x_default, bool short_circuit=true) {
  return conditional(ind, x, x_default, short_circuit);
}

DECL bool casadi_depends_on(const M& f, const M& arg) {
  return depends_on(f, arg);
}

DECL M casadi_solve(const M& A, const M& b) {
  return solve(A, b);
}

DECL M casadi_solve(const M& A, const M& b,
                       const std::string& lsolver,
                       const casadi::Dict& opts = casadi::Dict()) {
  return solve(A, b, lsolver, opts);
}

DECL M casadi_pinv(const M& A) {
  return pinv(A);
}

DECL M casadi_pinv(const M& A, const std::string& lsolver,
                      const casadi::Dict& opts = casadi::Dict()) {
  return pinv(A, lsolver, opts);
}

DECL M casadi_jacobian(const M &ex, const M &arg) {
  return jacobian(ex, arg);
}

DECL M casadi_jtimes(const M& ex, const M& arg, const M& v, bool tr=false) {
  return jtimes(ex, arg, v, tr);
}

DECL std::vector<bool> casadi_nl_var(const M& expr, const M& var) {
  return nl_var(expr, var);
}

DECL M casadi_gradient(const M &ex, const M &arg) {
  return gradient(ex, arg);
}

DECL M casadi_tangent(const M &ex, const M &arg) {
  return tangent(ex, arg);
}

DECL M casadi_hessian(const M& ex, const M& arg, M& OUTPUT1) {
  return hessian(ex, arg, OUTPUT1);
}

DECL int casadi_n_nodes(const M& A) {
  return n_nodes(A);
}

DECL std::string casadi_print_operator(const M& xb,
                                                  const std::vector<std::string>& args) {
  return print_operator(xb, args);
}
DECL M casadi_repsum(const M& A, int n, int m=1) {
  return repsum(A, n, m);
}

#endif // FLAG & IS_MEMBER

#if FLAG & IS_GLOBAL
DECL M casadi_substitute(const M& ex, const M& v, const M& vdef) {
  return substitute(ex, v, vdef);
}

DECL std::vector< M > casadi_substitute(const std::vector< M >& ex,
                                         const std::vector< M >& v,
                                         const std::vector< M >& vdef) {
  return substitute(ex, v, vdef);
}

DECL void casadi_substitute_inplace(const std::vector< M >& v,
                                      std::vector< M >& INOUT1,
                                      std::vector< M >& INOUT2,
                                      bool reverse=false) {
  return substitute_inplace(v, INOUT1, INOUT2, reverse);
}

DECL void casadi_shared(const std::vector< M >& ex,
                               std::vector< M >& OUTPUT1,
                               std::vector< M >& OUTPUT2,
                               std::vector< M >& OUTPUT3,
                               const std::string& v_prefix="v_",
                               const std::string& v_suffix="") {
  shared(ex, OUTPUT1, OUTPUT2, OUTPUT3, v_prefix, v_suffix);
}

#endif // FLAG & IS_GLOBAL
%enddef

%define GENERIC_MATRIX_ALL(DECL, FLAG)
GENERIC_MATRIX_FUN(DECL, (FLAG | IS_MX), MX)
GENERIC_MATRIX_FUN(DECL, (FLAG | IS_IMATRIX), Matrix<int>)
GENERIC_MATRIX_FUN(DECL, (FLAG | IS_DMATRIX), Matrix<double>)
GENERIC_MATRIX_FUN(DECL, (FLAG | IS_SX), Matrix<SXElem>)
%enddef

%define GENERIC_EXPRESSION_FUN(DECL, FLAG, M)
#if FLAG & IS_MEMBER
DECL M casadi_plus(const M& x, const M& y) { return x+y; }
DECL M casadi_minus(const M& x, const M& y) { return x-y; }
DECL M casadi_times(const M& x, const M& y) { return x*y; }
DECL M casadi_rdivide(const M& x, const M& y) { return x/y; }
DECL M casadi_ldivide(const M& x, const M& y) { return y/x; }
DECL M casadi_lt(const M& x, const M& y) { return x<y; }
DECL M casadi_le(const M& x, const M& y) { return x<=y; }
DECL M casadi_gt(const M& x, const M& y) { return x>y; }
DECL M casadi_ge(const M& x, const M& y) { return x>=y; }
DECL M casadi_eq(const M& x, const M& y) { return x==y; }
DECL M casadi_ne(const M& x, const M& y) { return x!=y; }
DECL M casadi_and(const M& x, const M& y) { return x&&y; }
DECL M casadi_or(const M& x, const M& y) { return x||y; }
DECL M casadi_not(const M& x) { return !x; }
DECL M casadi_abs(const M& x) { return fabs(x); }
DECL M casadi_sqrt(const M& x) { return sqrt(x); }
DECL M casadi_sin(const M& x) { return sin(x); }
DECL M casadi_cos(const M& x) { return cos(x); }
DECL M casadi_tan(const M& x) { return tan(x); }
DECL M casadi_atan(const M& x) { return atan(x); }
DECL M casadi_asin(const M& x) { return asin(x); }
DECL M casadi_acos(const M& x) { return acos(x); }
DECL M casadi_tanh(const M& x) { return tanh(x); }
DECL M casadi_sinh(const M& x) { return sinh(x); }
DECL M casadi_cosh(const M& x) { return cosh(x); }
DECL M casadi_atanh(const M& x) { return atanh(x); }
DECL M casadi_asinh(const M& x) { return asinh(x); }
DECL M casadi_acosh(const M& x) { return acosh(x); }
DECL M casadi_exp(const M& x) { return exp(x); }
DECL M casadi_log(const M& x) { return log(x); }
DECL M casadi_log10(const M& x) { return log10(x); }
DECL M casadi_floor(const M& x) { return floor(x); }
DECL M casadi_ceil(const M& x) { return ceil(x); }
DECL M casadi_erf(const M& x) { return erf(x); }
DECL M casadi_erfinv(const M& x) { using casadi::erfinv; return erfinv(x); }
DECL M casadi_sign(const M& x) { using casadi::sign; return sign(x); }
DECL M casadi_power(const M& x, const M& n) { return pow(x, n); }
DECL M casadi_mod(const M& x, const M& y) { return fmod(x, y); }
DECL M casadi_atan2(const M& x, const M& y) { return atan2(x, y); }
DECL M casadi_min(const M& x, const M& y) { return fmin(x, y); }
DECL M casadi_max(const M& x, const M& y) { return fmax(x, y); }
DECL M casadi_simplify(const M& x) { using casadi::simplify; return simplify(x); }
DECL bool casadi_is_equal(const M& x, const M& y, int depth=0) { using casadi::is_equal; return is_equal(x, y, depth); }
DECL M casadi_copysign(const M& x, const M& y) { return copysign(x, y); }
DECL M casadi_constpow(const M& x, const M& y) { using casadi::constpow; return constpow(x, y); }
#endif // FLAG & IS_MEMBER
%enddef

%define GENERIC_EXPRESSION_ALL(DECL, FLAG)
GENERIC_EXPRESSION_FUN(DECL, (FLAG | IS_MX), MX)
GENERIC_EXPRESSION_FUN(DECL, (FLAG | IS_IMATRIX), Matrix<int>)
GENERIC_EXPRESSION_FUN(DECL, (FLAG | IS_DMATRIX), Matrix<double>)
GENERIC_EXPRESSION_FUN(DECL, (FLAG | IS_SX), Matrix<SXElem>)
GENERIC_EXPRESSION_FUN(DECL, (FLAG | IS_DOUBLE), double)
%enddef

%define MATRIX_FUN(DECL, FLAG, M)
#if FLAG & IS_MEMBER
DECL M casadi_all(const M& x) {
  return all(x);
}

DECL M casadi_any(const M& x) {
  return any(x);
}

DECL M casadi_adj(const M& A) {
  return adj(A);
}

DECL M casadi_getMinor(const M& x, int i, int j) {
  return getMinor(x, i, j);
}

DECL M casadi_cofactor(const M& x, int i, int j) {
  return cofactor(x, i, j);
}

DECL void casadi_qr(const M& A, M& OUTPUT1, M& OUTPUT2) {
  return qr(A, OUTPUT1, OUTPUT2);
}

DECL M casadi_chol(const M& A) {
  return chol(A);
}

DECL M casadi_norm_inf_mul(const M& x, const M& y) {
  return norm_inf_mul(x, y);
}

DECL M casadi_sparsify(const M& A, double tol=0) {
  return sparsify(A, tol);
}

DECL void casadi_expand(const M& ex, M& OUTPUT1, M& OUTPUT2) {
  expand(ex, OUTPUT1, OUTPUT2);
}

DECL M casadi_pw_const(const M &t, const M& tval, const M& val) {
  return pw_const(t, tval, val);
}

DECL M casadi_pw_lin(const M& t, const M& tval, const M& val) {
  return pw_lin(t, tval, val);
}

DECL M casadi_heaviside(const M& x) {
  return heaviside(x);
}

DECL M casadi_rectangle(const M& x) {
  return rectangle(x);
}

DECL M casadi_triangle(const M& x) {
  return triangle(x);
}

DECL M casadi_ramp(const M& x) {
  return ramp(x);
}

DECL M casadi_gauss_quadrature(const M& f, const M& x,
                               const M& a, const M& b,
                               int order=5) {
  return gauss_quadrature(f, x, a, b, order);
}

DECL M casadi_gauss_quadrature(const M& f, const M& x,
                               const M& a, const M& b,
                               int order, const M& w) {
  return gauss_quadrature(f, x, a, b, order, w);
}

DECL M casadi_taylor(const M& ex, const M& x, const M& a=0, int order=1) {
  return taylor(ex, x, a, order);
}

DECL M casadi_mtaylor(const M& ex, const M& x, const M& a, int order=1) {
  return mtaylor(ex, x, a, order);
}

DECL M casadi_mtaylor(const M& ex, const M& x, const M& a, int order,
                      const std::vector<int>& order_contributions) {
  return mtaylor(ex, x, a, order, order_contributions);
}

DECL M casadi_poly_coeff(const M& ex,
                         const M&x) {
  return poly_coeff(ex, x);
}

DECL M casadi_poly_roots(const M& p) {
  return poly_roots(p);
}

DECL M casadi_eig_symbolic(const M& m) {
  return eig_symbolic(m);
}

#endif
%enddef

%define MATRIX_ALL(DECL, FLAG)
MATRIX_FUN(DECL, (FLAG | IS_IMATRIX), Matrix<int>)
MATRIX_FUN(DECL, (FLAG | IS_DMATRIX), Matrix<double>)
MATRIX_FUN(DECL, (FLAG | IS_SX), Matrix<SXElem>)
%enddef

%define MX_FUN(DECL, FLAG, M)
#if FLAG & IS_MEMBER
DECL M casadi_find(const M& x) {
  return find(x);
}
#endif // FLAG & IS_MEMBER

#if FLAG & IS_GLOBAL
DECL std::vector< M >
casadi_matrix_expand(const std::vector< M >& e,
                     const std::vector< M > &boundary = std::vector< M >(),
                     const Dict& options = Dict()) {
  return matrix_expand(e, boundary, options);
}

DECL M casadi_matrix_expand(const M& e,
                            const std::vector< M > &boundary = std::vector< M >(),
                            const Dict& options = Dict()) {
  return matrix_expand(e, boundary, options);
}

DECL M casadi_graph_substitute(const M& ex, const std::vector< M >& v,
                         const std::vector< M > &vdef) {
  return graph_substitute(ex, v, vdef);
}

DECL std::vector< M >
casadi_graph_substitute(const std::vector< M > &ex,
                 const std::vector< M > &v,
                 const std::vector< M > &vdef) {
  return graph_substitute(ex, v, vdef);
}

#endif
%enddef

%define MX_ALL(DECL, FLAG)
MX_FUN(DECL, (FLAG | IS_MX), MX)
%enddef

%template(PrintSX)           casadi::PrintableObject<casadi::Matrix<casadi::SXElem> >;

%include <casadi/core/matrix.hpp>

%template(DM) casadi::Matrix<double>;
%extend casadi::Matrix<double> {
   %template(DM) Matrix<int>;
   %template(DM) Matrix<SXElem>;
};

%template(IM) casadi::Matrix<int>;
%extend casadi::Matrix<int> {
   %template(IM) Matrix<double>;
   %template(IM) Matrix<SXElem>;
};

namespace casadi{
  %extend Matrix<double> {
    void assign(const casadi::Matrix<double>&rhs) { (*$self)=rhs; }
    %matrix_helpers(casadi::Matrix<double>)

  }
  %extend Matrix<int> {
    void assign(const casadi::Matrix<int>&rhs) { (*$self)=rhs; }
    %matrix_helpers(casadi::Matrix<int>)

  }
}

// Extend DM with SWIG unique features
namespace casadi{
  %extend Matrix<double> {
    // Convert to a dense matrix
    GUESTOBJECT* full() const {
#ifdef SWIGPYTHON
      npy_intp dims[2] = {$self->size1(), $self->size2()};
      PyObject* ret = PyArray_SimpleNew(2, dims, NPY_DOUBLE);
      double* d = static_cast<double*>(array_data(ret));
      casadi_densify($self->ptr(), $self->sparsity(), d, true); // Row-major
      return ret;
#elif defined(SWIGMATLAB)
      mxArray *p  = mxCreateDoubleMatrix($self->size1(), $self->size2(), mxREAL);
      double* d = static_cast<double*>(mxGetData(p));
      casadi_densify($self->ptr(), $self->sparsity(), d, false); // Column-major
      return p;
#else
      return 0;
#endif
    }

#ifdef SWIGMATLAB
    // Convert to a sparse matrix
    GUESTOBJECT* sparse() const {
      mxArray *p  = mxCreateSparse($self->size1(), $self->size2(), $self->nnz(), mxREAL);
      casadi::casadi_copy($self->ptr(), $self->nnz(), static_cast<double*>(mxGetData(p)));
      std::copy($self->colind(), $self->colind()+$self->size2()+1, mxGetJc(p));
      std::copy($self->row(), $self->row()+$self->nnz(), mxGetIr(p));
      return p;
    }
#endif
  }

  %extend Matrix<int> {
    // Convert to a dense matrix
    GUESTOBJECT* full() const {
#ifdef SWIGPYTHON
      npy_intp dims[2] = {$self->size1(), $self->size2()};
      PyObject* ret = PyArray_SimpleNew(2, dims, NPY_INT);
      int* d = static_cast<int*>(array_data(ret));
      casadi_densify($self->ptr(), $self->sparsity(), d, true); // Row-major
      return ret;
#elif defined(SWIGMATLAB)
      mxArray *p  = mxCreateDoubleMatrix($self->size1(), $self->size2(), mxREAL);
      std::vector<double> nz = $self->get_nonzeros<double>();
      double* d = static_cast<double*>(mxGetData(p));
      if (!nz.empty()) casadi_densify(&nz[0], $self->sparsity(), d, false); // Column-major
      return p;
#else
      return 0;
#endif
    }

#ifdef SWIGMATLAB
    // Convert to a sparse matrix
    GUESTOBJECT* sparse() const {
      mxArray *p  = mxCreateSparse($self->size1(), $self->size2(), $self->nnz(), mxREAL);
      std::vector<double> nz = $self->get_nonzeros<double>();
      if (!nz.empty()) casadi::casadi_copy(&nz[0], $self->nnz(), static_cast<double*>(mxGetData(p)));
      std::copy($self->colind(), $self->colind()+$self->size2()+1, mxGetJc(p));
      std::copy($self->row(), $self->row()+$self->nnz(), mxGetIr(p));
      return p;
    }
#endif
  }
} // namespace casadi


#ifdef SWIGPYTHON
namespace casadi{
%extend Matrix<double> {

%python_array_wrappers(999.0)

// The following code has some trickery to fool numpy ufunc.
// Normally, because of the presence of __array__, an ufunctor like nump.sqrt
// will unleash its activity on the output of __array__
// However, we wish DM to remain a DM
// So when we receive a call from a functor, we return a dummy empty array
// and return the real result during the postprocessing (__array_wrap__) of the functor.
%pythoncode %{
  def __array_custom__(self,*args,**kwargs):
    if "dtype" in kwargs and not(isinstance(kwargs["dtype"],n.double)):
      return n.array(self.full(),dtype=kwargs["dtype"])
    else:
      return self.full()
%}

%pythoncode %{
  def sparse(self):
    import numpy as n
    import warnings
    with warnings.catch_warnings():
      warnings.simplefilter("ignore")
      from scipy.sparse import csc_matrix
    return csc_matrix( (self.nonzeros(),self.row(),self.colind()), shape = self.shape, dtype=n.double )

  def tocsc(self):
    return self.sparse()

%}


#ifdef WITH_PYTHON3
%pythoncode %{
  def __bool__(self):
    if self.numel()!=1:
      raise Exception("Only a scalar can be cast to a float")
    if self.nnz()==0:
      return False
    return float(self)!=0
%}
#else
%pythoncode %{
  def __nonzero__(self):
    if self.numel()!=1:
      raise Exception("Only a scalar can be cast to a float")
    if self.nnz()==0:
      return False
    return float(self)!=0
%}
#endif

%pythoncode %{
  def __abs__(self):
    return abs(float(self))
%}

}; // extend Matrix<double>

%extend Matrix<int> {

  %python_array_wrappers(998.0)

  %pythoncode %{
    def __abs__(self):
      return abs(int(self))
  %}
} // extend Matrix<int>


// Logic for pickling

%extend Matrix<int> {

  %pythoncode %{
    def __setstate__(self, state):
        sp = Sparsity.__new__(Sparsity)
        sp.__setstate__(state["sparsity"])
        self.__init__(sp,state["data"])

    def __getstate__(self):
        return {"sparsity" : self.sparsity().__getstate__(), "data": numpy.array(self.nonzeros(),dtype=int)}
  %}
}

%extend Matrix<double> {

  %pythoncode %{
    def __setstate__(self, state):
        sp = Sparsity.__new__(Sparsity)
        sp.__setstate__(state["sparsity"])
        self.__init__(sp,state["data"])

    def __getstate__(self):
        return {"sparsity" : self.sparsity().__getstate__(), "data": numpy.array(self.nonzeros(),dtype=float)}
  %}

}


} // namespace casadi
#endif // SWIGPYTHON

%include <casadi/core/sx/sx_elem.hpp>

#ifdef SWIGPYTHON
%extend casadi::Sparsity{
    %pythoncode %{
        @property
        def shape(self):
            return (self.size1(),self.size2())

        @property
        def T(self):
            return _casadi.transpose(self)

        def __array__(self,*args,**kwargs):
            return DM.ones(self).full()
    %}
};

#endif // SWIGPYTHON

#ifdef SWIGPYTHON
%pythoncode %{

try:
  import numpy

  def constpow(x,y):
    pass

  constpow=numpy.frompyfunc(constpow,2,1)
except:
  pass
%}
#endif // SWIGPYTHON

namespace casadi {
%extend Matrix<SXElem>{
    %matrix_helpers(casadi::Matrix<casadi::SXElem>)

  #ifdef SWIGPYTHON
  %python_array_wrappers(1001.0)
  #endif // SWIGPYTHON

};

} // namespace casadi

#ifdef SWIGPYTHON
#include <arrayobject.h>
%template()    std::vector<PyObject*>;
#endif // SWIGPYTHON

%template(SX) casadi::Matrix<casadi::SXElem>;
%extend casadi::Matrix<casadi::SXElem> {
   %template(SX) Matrix<int>;
   %template(SX) Matrix<double>;
};

%include <casadi/core/mx/mx.hpp>

%extend casadi::MX{
  %matrix_helpers(casadi::MX)
  #ifdef SWIGPYTHON
  %python_array_wrappers(1002.0)
  #endif //SWIGPYTHON
};

#ifdef SWIGPYTHON
%pythoncode %{
def attach_return_type(f,t):
  if not(hasattr(f,'func_annotations')):
    f.func_annotations = {}
  if not(isinstance(getattr(f,'func_annotations'),dict)):
    raise Exception("Cannot annotate this python Method to be a sparsitygenerator. Method has func_annotations attribute with unknown type.")
  f.func_annotations["return"] = t
  return f

def pyevaluate(f):
  return attach_return_type(f,None)

def pycallback(f):
  return attach_return_type(f,int)


def pyfunction(inputs,outputs):
  def wrap(f):

    @pyevaluate
    def fcustom(f2):
      res = f([f2.getInput(i) for i in range(f2.n_in())])
      if not isinstance(res,list):
        res = [res]
      for i in range(f2.n_out()):
        f2.setOutput(res[i],i)
    import warnings

    with warnings.catch_warnings():
      warnings.filterwarnings("ignore",category=DeprecationWarning)
      Fun = CustomFunction("CustomFunction",fcustom,inputs,outputs)
      return Fun

  return wrap

def PyFunction(name, obj, inputs, outputs, opts={}):
    @pyevaluate
    def fcustom(f):
      res = [f.getOutput(i) for i in range(f.n_out())]
      obj.evaluate([f.getInput(i) for i in range(f.n_in())],res)
      for i in range(f.n_out()): f.setOutput(res[i], i)

    import warnings

    with warnings.catch_warnings():
      warnings.filterwarnings("ignore",category=DeprecationWarning)
      return CustomFunction("CustomFunction", fcustom,
                            inputs, outputs, opts)

%}
#endif

%include <casadi/core/function/function.hpp>
#ifdef SWIGPYTHON
namespace casadi{
%extend Function {
  %pythoncode %{
    def __call__(self, *args, **kwargs):
      # Either named inputs or ordered inputs
      if len(args)>0 and len(kwargs)>0:
        raise SyntaxError('Function evaluation requires all arguments to be named or none')
      if len(args)>0:
        # Ordered inputs -> return tuple
        ret = self.call(args)
        if len(ret)==0:
          return None
        elif len(ret)==1:
          return ret[0]
        else:
          return tuple(ret)
      else:
        # Named inputs -> return dictionary
        return self.call(kwargs)
  %}
 }
}
#endif // SWIGPYTHON

#ifdef SWIGMATLAB
namespace casadi{
%extend Function {
  %matlabcode %{
    function varargout = paren(self, varargin)
      if nargin==1 || (nargin>=2 && ischar(varargin{1}))
        % Named inputs: return struct
        assert(nargout<2, 'Syntax error');
        assert(mod(nargin,2)==1, 'Syntax error');
        arg = struct;
        for i=1:2:nargin-1
          assert(ischar(varargin{i}), 'Syntax error');
          arg.(varargin{i}) = varargin{i+1};
        end
        res = self.call(arg);
        varargout{1} = res;
      else
        % Ordered inputs: return variable number of outputs
        res = self.call(varargin);
        assert(nargout<=numel(res), 'Too many outputs');
        for i=1:max(min(1,numel(res)),nargout)
          varargout{i} = res{i};
        end
      end
    end
  %}
 }
}
#endif // SWIGMATLAB
%include <casadi/core/function/external.hpp>
%include <casadi/core/function/jit.hpp>
%include <casadi/core/function/integrator.hpp>
%include <casadi/core/function/conic.hpp>
%include <casadi/core/function/nlpsol.hpp>
%include <casadi/core/function/rootfinder.hpp>
%include <casadi/core/function/linsol.hpp>
%include <casadi/core/function/interpolant.hpp>

%feature("copyctor", "0") casadi::CodeGenerator;
%include <casadi/core/function/code_generator.hpp>

#ifdef SWIGMATLAB
// Wrap (static) member functions
%feature("nonstatic");
namespace casadi {
  %extend SparsityInterfaceCommon {
    SPARSITY_INTERFACE_ALL(static inline, IS_MEMBER)
  }
  %extend GenericExpressionCommon {
    GENERIC_EXPRESSION_ALL(static inline, IS_MEMBER)
  }
  %extend GenericMatrixCommon {
    GENERIC_MATRIX_ALL(static inline, IS_MEMBER)
  }
  %extend MatrixCommon {
    MATRIX_ALL(static inline, IS_MEMBER)
  }
  %extend MX {
    MX_ALL(static inline, IS_MEMBER)
  }
} // namespace casadi
%feature("nonstatic", "");
// Member functions already wrapped
#define FLAG IS_GLOBAL
#else // SWIGMATLAB
// Need to wrap member functions below
#define FLAG (IS_GLOBAL | IS_MEMBER)
#endif // SWIGMATLAB

// Wrap non-member functions, possibly with casadi_ prefix

%inline {
  namespace casadi {
    SPARSITY_INTERFACE_ALL(inline, FLAG)
    GENERIC_EXPRESSION_ALL(inline, FLAG)
    GENERIC_MATRIX_ALL(inline, FLAG)
    MATRIX_ALL(inline, FLAG)
    MX_ALL(inline, FLAG)
  }
}

// Wrap the casadi_ prefixed functions in member functions
#ifdef SWIGPYTHON
#ifdef WITH_PYTHON3
namespace casadi {
  %extend GenericExpressionCommon {
    %pythoncode %{
      def __hash__(self): return SharedObject.__hash__(self)
    %}
  }
}
%rename(__hash__) element_hash;
#endif
namespace casadi {
  %extend GenericExpressionCommon {
    %pythoncode %{
      def __add__(x, y): return _casadi.plus(x, y)
      def __radd__(x, y): return _casadi.plus(y, x)
      def __sub__(x, y): return _casadi.minus(x, y)
      def __rsub__(x, y): return _casadi.minus(y, x)
      def __mul__(x, y): return _casadi.times(x, y)
      def __rmul__(x, y): return _casadi.times(y, x)
      def __div__(x, y): return _casadi.rdivide(x, y)
      def __rdiv__(x, y): return _casadi.rdivide(y, x)
      def __truediv__(x, y): return _casadi.rdivide(x, y)
      def __rtruediv__(x, y): return _casadi.rdivide(y, x)
      def __lt__(x, y): return _casadi.lt(x, y)
      def __rlt__(x, y): return _casadi.lt(y, x)
      def __le__(x, y): return _casadi.le(x, y)
      def __rle__(x, y): return _casadi.le(y, x)
      def __gt__(x, y): return _casadi.lt(y, x)
      def __rgt__(x, y): return _casadi.lt(x, y)
      def __ge__(x, y): return _casadi.le(y, x)
      def __rge__(x, y): return _casadi.le(x, y)
      def __eq__(x, y): return _casadi.eq(x, y)
      def __req__(x, y): return _casadi.eq(y, x)
      def __ne__(x, y): return _casadi.ne(x, y)
      def __rne__(x, y): return _casadi.ne(y, x)
      def __pow__(x, n): return _casadi.power(x, n)
      def __rpow__(n, x): return _casadi.power(x, n)
      def __arctan2__(x, y): return _casadi.atan2(x, y)
      def __rarctan2__(y, x): return _casadi.atan2(x, y)
      def fmin(x, y): return _casadi.fmin(x, y)
      def fmax(x, y): return _casadi.fmax(x, y)
      def __fmin__(x, y): return _casadi.fmin(x, y)
      def __rfmin__(y, x): return _casadi.fmin(x, y)
      def __fmax__(x, y): return _casadi.fmax(x, y)
      def __rfmax__(y, x): return _casadi.fmax(x, y)
      def logic_and(x, y): return _casadi.logic_and(x, y)
      def logic_or(x, y): return _casadi.logic_or(x, y)
      def fabs(x): return _casadi.fabs(x)
      def sqrt(x): return _casadi.sqrt(x)
      def sin(x): return _casadi.sin(x)
      def cos(x): return _casadi.cos(x)
      def tan(x): return _casadi.tan(x)
      def arcsin(x): return _casadi.asin(x)
      def arccos(x): return _casadi.acos(x)
      def arctan(x): return _casadi.atan(x)
      def sinh(x): return _casadi.sinh(x)
      def cosh(x): return _casadi.cosh(x)
      def tanh(x): return _casadi.tanh(x)
      def arcsinh(x): return _casadi.asinh(x)
      def arccosh(x): return _casadi.acosh(x)
      def arctanh(x): return _casadi.atanh(x)
      def exp(x): return _casadi.exp(x)
      def log(x): return _casadi.log(x)
      def log10(x): return _casadi.log10(x)
      def floor(x): return _casadi.floor(x)
      def ceil(x): return _casadi.ceil(x)
      def erf(x): return _casadi.erf(x)
      def sign(x): return _casadi.sign(x)
      def fmod(x, y): return _casadi.mod(x, y)
      def __copysign__(x, y): return _casadi.copysign(x, y)
      def __rcopysign__(y, x): return _casadi.copysign(x, y)
      def copysign(x, y): return _casadi.copysign(x, y)
      def rcopysign(y, x): return _casadi.copysign(x, y)
      def __constpow__(x, y): return _casadi.constpow(x, y)
      def __rconstpow__(y, x): return _casadi.constpow(x, y)
      def constpow(x, y): return _casadi.constpow(x, y)
      def rconstpow(y, x): return _casadi.constpow(x, y)
    %}
  }

  %extend GenericMatrixCommon {
    %pythoncode %{
      def __mldivide__(x, y): return _casadi.mldivide(x, y)
      def __rmldivide__(y, x): return _casadi.mldivide(x, y)
      def __mrdivide__(x, y): return _casadi.mrdivide(x, y)
      def __rmrdivide__(y, x): return _casadi.mrdivide(x, y)
      def __mpower__(x, y): return _casadi.mpower(x, y)
      def __rmpower__(y, x): return _casadi.mpower(x, y)
    %}
  }

} // namespace casadi
#endif // SWIGPYTHON

%feature("director") casadi::Callback;

%include <casadi/core/function/importer.hpp>
%include <casadi/core/function/callback.hpp>
%include <casadi/core/global_options.hpp>
%include <casadi/core/casadi_meta.hpp>
%include <casadi/core/misc/integration_tools.hpp>
%include <casadi/core/misc/nlp_builder.hpp>
%include <casadi/core/misc/variable.hpp>
%include <casadi/core/misc/dae_builder.hpp>
%include <casadi/core/misc/xml_file.hpp>
#ifdef SWIGPYTHON

#ifdef WITH_PYTHON3
%pythoncode %{
def swig_monkeypatch(v,cl=True):
  import re
  if hasattr(v,"__monkeypatched__"):
    return v
  def foo(*args,**kwargs):
    try:
      return v(*args,**kwargs)
    except NotImplementedError as e:
      import sys
      exc_info = sys.exc_info()
      if e.args[0].startswith("Wrong number or type of arguments for overloaded function"):

        s = e.args[0]
        s = s.replace("'new_","'")
        #s = re.sub(r"overloaded function '(\w+?)_(\w+)'",r"overloaded function '\1.\2'",s)
        m = re.search("overloaded function '([\w\.]+)'",s)
        if m:
          name = m.group(1)
          name = name.replace(".__call__","")
        else:
          name = "method"
        ne = NotImplementedError(swig_typename_convertor_cpp2python(s)+"You have: %s(%s)\n" % (name,", ".join([swig_typename_convertor_python2cpp(i) for i in (args[1:] if cl else args)]+ ["%s=%s" % (k,swig_typename_convertor_python2cpp(vv)) for k,vv in kwargs.items()])))
        raise ne.with_traceback(exc_info[2].tb_next)
      else:
        raise exc_info[1].with_traceback(exc_info[2].tb_next)
    except TypeError as e:
      import sys
      exc_info = sys.exc_info()

      methodname = "method"
      try:
        methodname = exc_info[2].tb_next.tb_frame.f_code.co_name
      except:
        pass

      if e.args[0].startswith("in method '"):
        s = e.args[0]
        s = re.sub(r"method '(\w+?)_(\w+)'",r"method '\1.\2'",s)
        m = re.search("method '([\w\.]+)'",s)
        if m:
          name = m.group(1)
          name = name.replace(".__call__","")
        else:
          name = "method"
        ne = TypeError(swig_typename_convertor_cpp2python(s)+" expected.\nYou have: %s(%s)\n" % (name,", ".join([swig_typename_convertor_python2cpp(i) for i in (args[1:] if cl else args)])))
        raise ne.with_traceback(exc_info[2].tb_next)
      elif e.args[0].startswith("Expecting one of"):
        s = e.args[0]
        conversion = {"mul": "*", "div": "/", "add": "+", "sub": "-","le":"<=","ge":">=","lt":"<","gt":">","eq":"==","pow":"**"}
        if methodname.startswith("__") and methodname[2:-2] in conversion:
          ne = TypeError(swig_typename_convertor_cpp2python(s)+"\nYou try to do: %s %s %s.\n" % (  swig_typename_convertor_python2cpp(args[0]),conversion[methodname[2:-2]] ,swig_typename_convertor_python2cpp(args[1]) ))
        elif methodname.startswith("__r") and methodname[3:-2] in conversion:
          ne = TypeError(swig_typename_convertor_cpp2python(s)+"\nYou try to do: %s %s %s.\n" % ( swig_typename_convertor_python2cpp(args[1]),  conversion[methodname[3:-2]], swig_typename_convertor_python2cpp(args[0]) ))
        else:
          ne = TypeError(swig_typename_convertor_cpp2python(s)+"\nYou have: (%s)\n" % (", ".join([swig_typename_convertor_python2cpp(i) for i in (args[1:] if cl else args)])))
        raise ne.with_traceback(exc_info[2].tb_next)
      else:
        s = e.args[0]
        ne = TypeError(s+"\nYou have: (%s)\n" % (", ".join([swig_typename_convertor_python2cpp(i) for i in (args[1:] if cl else args)] + ["%s=%s" % (k,swig_typename_convertor_python2cpp(vv)) for k,vv in kwargs.items()]  )))
        raise ne.with_traceback(exc_info[2].tb_next)
    except AttributeError as e:
      import sys
      exc_info = sys.exc_info()
      if e.args[0]=="type object 'object' has no attribute '__getattr__'":
        # swig 3.0 bug
        ne = AttributeError("Unkown attribute: %s has no attribute '%s'." % (str(args[1]),args[2]))
        raise ne.with_traceback(exc_info[2].tb_next)
      else:
        raise exc_info[1].with_traceback(exc_info[2].tb_next)
    except Exception as e:
      import sys
      exc_info = sys.exc_info()
      raise exc_info[1].with_traceback(exc_info[2].tb_next)
  if v.__doc__ is not None:
    foo.__doc__ = swig_typename_convertor_cpp2python(v.__doc__)
  foo.__name__ = v.__name__
  foo.__monkeypatched__ = True
  return foo
%}
#else
%pythoncode %{
def swig_monkeypatch(v,cl=True):
  import re
  if hasattr(v,"__monkeypatched__"):
    return v
  def foo(*args,**kwargs):
    try:
      return v(*args,**kwargs)
    except NotImplementedError as e:
      import sys
      exc_info = sys.exc_info()
      if e.message.startswith("Wrong number or type of arguments for overloaded function"):

        s = e.args[0]
        s = s.replace("'new_","'")
        #s = re.sub(r"overloaded function '(\w+?)_(\w+)'",r"overloaded function '\1.\2'",s)
        m = re.search("overloaded function '([\w\.]+)'",s)
        if m:
          name = m.group(1)
          name = name.replace(".__call__","")
        else:
          name = "method"
        ne = NotImplementedError(swig_typename_convertor_cpp2python(s)+"You have: %s(%s)\n" % (name,", ".join(map(swig_typename_convertor_python2cpp,args[1:] if cl else args)+ ["%s=%s" % (k,swig_typename_convertor_python2cpp(vv)) for k,vv in kwargs.items()])))
        raise ne.__class__, ne, exc_info[2].tb_next
      else:
        raise exc_info[1], None, exc_info[2].tb_next
    except TypeError as e:
      import sys
      exc_info = sys.exc_info()

      methodname = "method"
      try:
        methodname = exc_info[2].tb_next.tb_frame.f_code.co_name
      except:
        pass

      if e.message.startswith("in method '"):
        s = e.args[0]
        s = re.sub(r"method '(\w+?)_(\w+)'",r"method '\1.\2'",s)
        m = re.search("method '([\w\.]+)'",s)
        if m:
          name = m.group(1)
          name = name.replace(".__call__","")
        else:
          name = "method"
        ne = TypeError(swig_typename_convertor_cpp2python(s)+" expected.\nYou have: %s(%s)\n" % (name,", ".join(map(swig_typename_convertor_python2cpp,args[1:] if cl else args))))
        raise ne.__class__, ne, exc_info[2].tb_next
      elif e.message.startswith("Expecting one of"):
        s = e.args[0]
        conversion = {"mul": "*", "div": "/", "add": "+", "sub": "-","le":"<=","ge":">=","lt":"<","gt":">","eq":"==","pow":"**"}
        if methodname.startswith("__") and methodname[2:-2] in conversion:
          ne = TypeError(swig_typename_convertor_cpp2python(s)+"\nYou try to do: %s %s %s.\n" % (  swig_typename_convertor_python2cpp(args[0]),conversion[methodname[2:-2]] ,swig_typename_convertor_python2cpp(args[1]) ))
        elif methodname.startswith("__r") and methodname[3:-2] in conversion:
          ne = TypeError(swig_typename_convertor_cpp2python(s)+"\nYou try to do: %s %s %s.\n" % ( swig_typename_convertor_python2cpp(args[1]),  conversion[methodname[3:-2]], swig_typename_convertor_python2cpp(args[0]) ))
        else:
          ne = TypeError(swig_typename_convertor_cpp2python(s)+"\nYou have: (%s)\n" % (", ".join(map(swig_typename_convertor_python2cpp,args[1:] if cl else args))))
        raise ne.__class__, ne, exc_info[2].tb_next
      else:
        s = e.args[0]
        ne = TypeError(s+"\nYou have: (%s)\n" % (", ".join(map(swig_typename_convertor_python2cpp,args[1:] if cl else args) + ["%s=%s" % (k,swig_typename_convertor_python2cpp(vv)) for k,vv in kwargs.items()]  )))
        raise ne.__class__, ne, exc_info[2].tb_next
    except AttributeError as e:
      import sys
      exc_info = sys.exc_info()
      if e.message=="type object 'object' has no attribute '__getattr__'":
        # swig 3.0 bug
        ne = AttributeError("Unkown attribute: %s has no attribute '%s'." % (str(args[1]),args[2]))
        raise ne.__class__, ne, exc_info[2].tb_next
      else:
        raise exc_info[1], None, exc_info[2].tb_next
    except Exception as e:
      import sys
      exc_info = sys.exc_info()
      raise exc_info[1], None, exc_info[2].tb_next

  if v.__doc__ is not None:
    foo.__doc__ = swig_typename_convertor_cpp2python(v.__doc__)
  foo.__name__ = v.__name__
  foo.__monkeypatched__ = True
  return foo

%}
#endif


%pythoncode %{

import sys
def swig_typename_convertor_cpp2python(s):
  import re
  s = s.replace("C/C++ prototypes","Python usages")
  s = s.replace("casadi::","")
  s = s.replace("MXDict","str:MX")
  s = s.replace("SXDict","str:SX")
  s = s.replace("std::string","str")
  s = s.replace(" const &","")
  s = s.replace("casadi_","")
  s = re.sub(r"\b((\w+)(< \w+ >)?)::\2\b",r"\1",s)
  s = re.sub("(const )?Matrix< ?SXElem *>( &)?",r"SX",s)
  s = re.sub("(const )?GenericMatrix< ?(\w+) *>( ?&)?",r"\2 ",s)
  s = re.sub("(const )?Matrix< ?int *>( ?&)?",r"IM ",s)
  s = re.sub("(const )?Matrix< ?double *>( ?&)?",r"DM ",s)
  s = re.sub("(const )?Matrix< ?(\w+) *>( ?&)?",r"array(\2) ",s)
  s = re.sub("(const )?GenericMatrix< ?([\w\(\)]+) *>( ?&)?",r"\2 ",s)
  s = re.sub(r"const (\w+) &",r"\1 ",s)
  s = re.sub(r"< [\w\(\)]+ +>\(",r"(",s)
  for i in range(5):
    s = re.sub(r"(const )? ?std::pair< ?([\w\(\)\]\[: ]+?) ?, ?([\w\(\)\]\[: ]+?) ?> ?&?",r"(\2,\3) ",s)
    s = re.sub(r"(const )? ?std::vector< ?([\w\(\)\[\] ]+) ?(, ?std::allocator< ?\2 ?>)? ?> ?&?",r"[\2] ",s)
  s = re.sub(r"\b(\w+)(< \w+ >)?::\1",r"\1",s)
  s = s.replace("casadi::","")
  s = s.replace("::",".")
  s = s.replace(".operator ()","")
  s = re.sub(r"([A-Z]\w+)Vector",r"[\1]",s)
  return s

def swig_typename_convertor_python2cpp(a):
  try:
    import numpy as np
  except:
    class NoExist:
      pass
    class Temp(object):
      ndarray = NoExist
    np = Temp()
  if isinstance(a,list):
    if len(a)>0:
      return "[%s]" % "|".join(set([swig_typename_convertor_python2cpp(i) for i in a]))
    else:
      return "[]"
  elif isinstance(a,tuple):
    return "(%s)" % ",".join([swig_typename_convertor_python2cpp(i) for i in a])
  elif isinstance(a,np.ndarray):
    return "np.array(%s)" % ",".join(set([swig_typename_convertor_python2cpp(i) for i in np.array(a).flatten().tolist()]))
  elif isinstance(a,dict):
    if len(a)>0:
      return "|".join(set([swig_typename_convertor_python2cpp(i) for i in a.keys()])) +":"+ "|".join(set([swig_typename_convertor_python2cpp(i) for i in a.values()]))
    else:
      return "dict"
  return type(a).__name__

import inspect
import copy

locals_copy = copy.copy(locals())
for name,cl in locals_copy.items():
  if not inspect.isclass(cl): continue

if sys.version_info >= (3, 0):
  for k,v in inspect.getmembers(cl, lambda x: inspect.ismethod(x) or inspect.isfunction(x)):
    if k == "__del__" or v.__name__ == "<lambda>": continue
    vv = v
    setattr(cl,k,swig_monkeypatch(vv))
else:
  for k,v in inspect.getmembers(cl, inspect.ismethod):
    if k == "__del__" or v.__name__ == "<lambda>": continue
    vv = v
    setattr(cl,k,swig_monkeypatch(vv))
  for k,v in inspect.getmembers(cl, inspect.isfunction):
    setattr(cl,k,staticmethod(swig_monkeypatch(v,cl=False)))

locals_copy = copy.copy(locals())
for name,v in locals_copy.items():
  if not inspect.isfunction(v): continue
  if name.startswith("swig") : continue
  p = swig_monkeypatch(v,cl=False)
  #setattr(casadi,name,p)
  import sys
  setattr(sys.modules[__name__], name, p)


%}

#endif

// Cleanup for dependent modules
%exception {
  $action
}
