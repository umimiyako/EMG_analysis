% 入力：サンプリング周波数[Hz]
% 入力：計測時間[sec]
Fs = 1000;
sec = 5;
    
% 入力：ファイル名
% 入力：区切り文字
% 入力：ヘッダ部分の行数
filename = '312.csv';
delimiterIn = ',';
headerlinesIn = 12;

% データを取り込んでemgとする
% emgの2列目を取り出してraw_columnとする
% データ数nの計算
% raw_columnを1からn行まで取り出してraw_noise_trendとする
emg = importdata(filename,delimiterIn,headerlinesIn);
raw_column = emg.data(:,2);
n = sec*Fs;
raw_noise_trend = raw_column(1:n,:);

% 標準偏差の3倍を超えて平均値から離れている要素を外れ値として検出し，1つ前の非外れ値に置き換える
% 直流成分を除去
raw_trend = filloutliers(raw_noise_trend,"previous","mean");
raw = detrend(raw_trend);

% 時刻インデックスの作成
tind = (1:n)/Fs;

% RMSによる整流・平滑化
% 入力：積分区間（データ点数）
% サンプリング周波数の1/20か1/10にする
wlength = 100;
smooth = zeros(size(raw));

% 積分区間データ長が偶数の場合，時間窓を積分時刻を中心に
% 左右対称とするため窓長を1増加させる
if mod(wlength, 2) == 0 
    wlength = wlength+1; 
end

% 時間窓の片側長さ
% データ長
nedge = floor(wlength/2);
dlen = length(raw);

% RMSの計算
for ii = 1:dlen

    % データの左端
    if(ii <= nedge)
        smooth(ii,1) = rms(raw(1:(ii+nedge), 1));
    end

    if(ii > nedge && ii < dlen - nedge)
        smooth(ii,1) = rms(raw((ii-nedge):(ii+nedge), 1));
    end

    % データの左端
    if(ii >= dlen - nedge)
        smooth(ii,1) = rms(raw((ii-nedge):dlen, 1));
    end

end

% 変数i,jの初期値を設定
% 0.1sずつなので1000Hz*0.1=100データごとに平均値を計算
i = 1;
j = 100;

% 平均値を格納する行列を作る
% 5sまでなので5s/0.1s=50区間
time_variation = zeros(1,50);

% 変数kを1から50まで変化させる
for k = 1:50
    
    % smoothをiからjまで取り出してextracted_smoothとする
    % 平均値を計算
    % 平均値をtime_variationのk行目に格納
    extracted_smooth = smooth(i:j,:);
    MEAN = mean(extracted_smooth);
    time_variation(1,k) = MEAN;
    
    % 取り出す範囲をずらす
    i = i + 100;
    j = j + 100;
end

% 最大平均値を求める
MAX = max(time_variation);