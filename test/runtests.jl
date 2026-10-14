using Test
using Dve

@testset "hello_world" begin
    @test hello_world("Hello", "Julia") == "Hello, Julia!"
    @test hello_world("Ciao", "mondo") == "Ciao, mondo!"
    @test_throws ArgumentError hello_world("", "x")
end
