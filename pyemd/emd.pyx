#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# distutils: language = c++

from libcpp.vector cimport vector
import cython

# Import both NumPy and the Cython declarations for NumPy
import numpy as np
cimport numpy as np


# Declare the interface to the C++ EMD library
# ============================================

cdef extern from "lib/emd_hat.hpp":
    cdef double emd_hat_gd_metric_double(vector[double],
                                         vector[double],
                                         vector[vector[double]]) except +


# NumPy array to C++ vector conversion
# ====================================

# See https://github.com/cython/cython/wiki/tutorials-NumpyPointerToC
@cython.boundscheck(False)
@cython.wraparound(False)
cdef vector[double] _np_array_to_vector(
    np.ndarray[double, ndim=1, mode="c"] array):
    """Convert a 1D numpy array to a C++ vector.

    :param array: A 1D numpy array of ``np.double``.
    """
    cdef vector[double] output_vector
    output_vector.reserve(array.size)
    output_vector.assign(&array[0], &array[0] + array.size)
    return output_vector


def _2d_np_array_to_2d_vector(np.ndarray[double, ndim=2, mode="c"] matrix):
    """Convert a 2D numpy array to a C++ vector of vectors.

    :param array: A 2D numpy array of ``np.double``.
    """
    cdef vector[vector[double]] output_matrix
    output_matrix.resize(array.shape[0])
    cdef vector[double] c_row
    for i in range(matrix.shape[0]):
        output_matrix[i] = _np_array_to_vector(row)
    return output_matrix


# Define the API
# ==============

def emd(np.ndarray[double, ndim=1, mode="c"] first_signature,
        np.ndarray[double, ndim=1, mode="c"] second_signature,
        np.ndarray[double, ndim=2, mode="c"] distance_matrix):
    """Compute the Earth Mover's Distance between the given signatures with the
    given distance matrix.

    :param first_signature: A 1D numpy array of ``np.double``, of length
        :math:`N`.
    :param second_signature: A 1D numpy array of ``np.double``, also of length
        :math:`N`..
    :param distance_matrix: A 2D numpy array of ``np.double``, of size
        :math:`N \cross N`.
    """
    # # Validation
    # if ([arg.dtype for arg in [first_signature, second_signature,
    #                            distance_matrix]] != [np.dtype('float64')] * 3):
    #     raise ValueError('Signatures and distance matrix must be of NumPy '
    #                      'datatype `float64`.')
    # N = first_signature.shape[0]
    # if (N != second_signature.shape[0]):
    #     raise ValueError('Signatures must be the same size.')
    # if ((N != distance_matrix.shape[0]) or (N != distance_matrix.shape[1])):
    #     raise ValueError('Distance matrix must be NxN, where N is the length of '
    #                      'the signatures.')
    # if (first_signature.ndim != 1) or (first_signature.ndim !=
    #                                    second_signature.ndim):
    #     raise ValueError('Signatures must be 1-dimensional.')
    # if (distance_matrix.ndim != 2):
    #     raise ValueError('Distance matrix must be 2-dimensional.')

    # Convert numpy input to C++ vectors
    cdef vector[double] c_first_signature
    cdef vector[double] c_second_signature
    cdef vector[vector[double]] c_distance_matrix
    c_first_signature = _np_array_to_vector(first_signature)
    c_second_signature = _np_array_to_vector(second_signature)
    c_distance_matrix = _2d_np_array_to_2d_vector(distance_matrix)

    return emd_hat_gd_metric_double(c_first_signature,
                                    c_second_signature,
                                    c_distance_matrix)
