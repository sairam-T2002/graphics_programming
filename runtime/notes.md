vector dot prodcut
[1, 2, 3] . [5, 6, 7] = 1*5 + 2*6 + 3*7 = 38

vector cross product
[1, 2, 3] x [5, 6, 7] = [2*7 - 3*6, 3*5 - 1*7, 1*6 - 2*5] = [-4, 8, -4]

scaling matrix (when this is multiplied to a vector the vector's components are scaled by Sx, Sy, and Sz)
[
   Sx, 0, 0, 0,
   0, Sy, 0, 0,
   0, 0, Sz, 0,
   0, 0, 0,  1
]

translation matrix (when this is multiplied to a vector the vector's components are translated by Tx, Ty, and Tz)
[
   1, 0, 0, Tx,
   0, 1, 0, Ty,
   0, 0, 1, Tz,
   0, 0, 0,  1
]

rotation matrix (when this is multiplied to a vector the vector's is rotated by θ around the x-axis)
[
   1, 0, 0, 0,
   0, cos(θ), -sin(θ), 0,
   0, sin(θ), cos(θ), 0,
   0, 0, 0,  1
]

rotation matrix (when this is multiplied to a vector the vector's is rotated by θ around the y-axis)
[
   cos(θ), 0, sin(θ), 0,
   0, 1, 0, 0,
   -sin(θ), 0, cos(θ), 0,
   0, 0, 0,  1
]

rotation matrix (when this is multiplied to a vector the vector's is rotated by θ around the z-axis)
[
   cos(θ), -sin(θ), 0, 0,
   sin(θ), cos(θ), 0, 0,
   0, 0, 1, 0,
   0, 0, 0,  1
]

rodrigues rotation matrix (when this is multiplied to a vector the vector's is rotated by θ around the axis defined by the unit vector u)
[
   cos(θ) + ux^2 * (1 - cos(θ)), ux * uy * (1 - cos(θ)) - uz * sin(θ), ux * uz * (1 - cos(θ)) + uy * sin(θ), 0,
   uy * ux * (1 - cos(θ)) + uz * sin(θ), cos(θ) + uy^2 * (1 - cos(θ)), uy * uz * (1 - cos(θ)) - ux * sin(θ), 0,
   uz * ux * (1 - cos(θ)) - uy * sin(θ), uz * uy * (1 - cos(θ)) + ux * sin(θ), cos(θ) + uz^2 * (1 - cos(θ)), 0,
   0,                            0,                                    0,                                    1
]
