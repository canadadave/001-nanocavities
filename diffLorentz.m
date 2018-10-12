function result = diffLorentz(xdata,ydata,coeff)

form = 'a+b*c/((x-x0)^2+c)-y';

%% Coefficients

% a -> flat response from sample
a = coeff(1);
% b -> amplitude of Lorentzian response
b = coeff(2);
% c -> linewidth
c = coeff(3);
% x0 -> position of resonance
x0 = coeff(4);
% phi -> phase  between 'a' and 'b'
phi = coeff(5)*pi;

result = sum((a^2+b^2*c^2./((xdata-x0).^2+c^2)+a*b*exp(1i*phi)*c./((xdata-x0)-1i*c)+a*b*exp(-1i*phi)*c./((xdata-x0)+1i*c)-ydata).^2);