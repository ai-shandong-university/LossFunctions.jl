function test_value(pen::ParameterLoss, f::Function)
    @testset "$(pen): " begin
        for i = 1:20
            w = randn(10)
            ref = value(pen, w, length(w))::Float64
            val = f(w)::Float64
            @test abs(ref - val) < 1e-10
            ref = value(pen, w, length(w)-1)::Float64
            val = f(w[1:(length(w)-1)])::Float64
            @test abs(ref - val) < 1e-10
        end
    end
end

function test_grad(pen::ParameterLoss, g::Function)
    @testset "$(pen): " begin
        for i = 1:20
            len = 10
            w = randn(len)
            ref = grad(pen, w)::Vector{Float64}
            buf = zeros(len)
            for i = 1:len
                buf[i] = deriv(pen, w[i])
            end
            val = g(w)::Vector{Float64}
            @test sumabs(ref - val) < 1e-10 * length(w)
            @test sumabs(buf - val) < 1e-10 * length(w)
            ref = grad(pen, w, len-1)::Vector{Float64}
            val = [g(w[1:(len-1)]); 0]::Vector{Float64}
            @test sumabs(ref - val) < 1e-10 * length(w)
            rnd = randn(len)
            buf = copy(rnd)
            ref = addgrad!(buf, pen, w)::Vector{Float64}
            val = g(w)::Vector{Float64}
            @test sumabs(ref - buf) < 1e-10 * length(w)
            @test sumabs(ref - (rnd + val)) < 1e-10 * length(w)
        end
    end
end

# ================================================================

@testset "Test penalties against reference function" begin
    function _l1pen(λ)
        _value(w) = λ * sumabs(w)
        _value
    end
    test_value(L1ParameterLoss(0.05), _l1pen(0.05))
    test_value(L1ParameterLoss(0.1), _l1pen(0.1))
    test_value(L1ParameterLoss(0.5), _l1pen(0.5))
    test_value(L1ParameterLoss(1), sumabs)

    function _l2pen(λ)
        _value(w) = λ/2 * sumabs2(w)
        _value
    end
    test_value(L2ParameterLoss(0.05), _l2pen(0.05))
    test_value(L2ParameterLoss(0.1), _l2pen(0.1))
    test_value(L2ParameterLoss(0.5), _l2pen(0.5))
    test_value(L2ParameterLoss(1), _l2pen(1))
    test_value(L2ParameterLoss(2), sumabs2)
end

@testset "Test gradient of penalty functions" begin
    function _l1pengrad(λ)
        _grad(w) = λ * sign(w)
        _grad
    end
    test_grad(L1ParameterLoss(0.05), _l1pengrad(0.05))
    test_grad(L1ParameterLoss(0.1), _l1pengrad(0.1))
    test_grad(L1ParameterLoss(0.5), _l1pengrad(0.5))
    test_grad(L1ParameterLoss(1), _l1pengrad(1))

    function _l2pengrad(λ)
        _grad(w) = λ * w
        _grad
    end
    test_grad(L2ParameterLoss(0.05), _l2pengrad(0.05))
    test_grad(L2ParameterLoss(0.1), _l2pengrad(0.1))
    test_grad(L2ParameterLoss(0.5), _l2pengrad(0.5))
    test_grad(L2ParameterLoss(1), _l2pengrad(1))
end

