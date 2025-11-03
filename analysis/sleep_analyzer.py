"""
Sleep analysis module for processing sleep data from various wearables.
Uses Pandas and SciPy for statistical analysis and trend detection.
"""
import json
import pandas as pd
import numpy as np
from typing import Dict, List, Any, Optional
from datetime import datetime, timedelta
from scipy import stats


def analyze_sleep_data(sleep_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Analyze sleep data and return comprehensive metrics.
    
    Args:
        sleep_data: JSON sleep data from wearable device
                  Expected format: {
                    'sessions': [...],
                    'stages': [...],
                    'start_time': 'ISO string',
                    'end_time': 'ISO string'
                  }
        
    Returns:
        Dictionary with sleep metrics including:
        - efficiency: Sleep efficiency percentage
        - total_sleep_duration: Total sleep in minutes
        - rem_percentage: REM sleep percentage
        - deep_sleep_percentage: Deep sleep percentage
        - light_sleep_percentage: Light sleep percentage
        - awake_percentage: Awake time percentage
        - sleep_latency: Time to fall asleep in minutes
        - wake_after_sleep_onset: Wake episodes after sleep onset
        - sleep_score: Overall sleep quality score (0-100)
    """
    try:
        # Parse input data
        sessions = sleep_data.get('sessions', [])
        if not sessions:
            # Try single session format
            return _analyze_single_session(sleep_data)
        
        # Analyze multiple sessions
        return _analyze_multiple_sessions(sessions)
    
    except Exception as e:
        return {
            'error': str(e),
            'efficiency': 0.0,
            'total_sleep_duration': 0,
            'rem_percentage': 0.0,
            'deep_sleep_percentage': 0.0,
            'light_sleep_percentage': 0.0,
            'awake_percentage': 0.0,
        }


def _analyze_single_session(data: Dict[str, Any]) -> Dict[str, Any]:
    """Analyze a single sleep session."""
    stages = data.get('stages', [])
    start_time = _parse_datetime(data.get('start_time'))
    end_time = _parse_datetime(data.get('end_time'))
    
    if not stages:
        return {
            'efficiency': 0.0,
            'total_sleep_duration': 0,
            'rem_percentage': 0.0,
            'deep_sleep_percentage': 0.0,
            'light_sleep_percentage': 0.0,
            'awake_percentage': 0.0,
            'sleep_latency': 0,
            'wake_after_sleep_onset': 0,
            'sleep_score': 0.0,
        }
    
    # Convert stages to DataFrame for analysis
    df = pd.DataFrame(stages)
    
    # Calculate total sleep (excluding awake)
    total_sleep = df[df['type'] != 'AWAKE']['duration'].sum()
    total_duration = (end_time - start_time).total_seconds() / 60 if start_time and end_time else total_sleep
    
    # Calculate efficiency
    efficiency = (total_sleep / total_duration * 100) if total_duration > 0 else 0.0
    
    # Calculate stage percentages
    rem_percentage = (df[df['type'] == 'REM']['duration'].sum() / total_sleep * 100) if total_sleep > 0 else 0.0
    deep_percentage = (df[df['type'] == 'DEEP']['duration'].sum() / total_sleep * 100) if total_sleep > 0 else 0.0
    light_percentage = (df[df['type'] == 'LIGHT']['duration'].sum() / total_sleep * 100) if total_sleep > 0 else 0.0
    awake_percentage = (df[df['type'] == 'AWAKE']['duration'].sum() / total_duration * 100) if total_duration > 0 else 0.0
    
    # Calculate sleep latency (time until first sleep stage)
    sleep_latency = 0
    if stages:
        first_stage = stages[0]
        if first_stage.get('type') == 'AWAKE':
            sleep_latency = first_stage.get('duration', 0)
    
    # Count wake episodes after sleep onset
    wake_after_sleep_onset = len(df[(df['type'] == 'AWAKE') & (df.index > 0)])
    
    # Calculate sleep score (0-100)
    sleep_score = _calculate_sleep_score(
        efficiency, rem_percentage, deep_percentage,
        total_sleep, sleep_latency, wake_after_sleep_onset
    )
    
    return {
        'efficiency': round(efficiency, 2),
        'total_sleep_duration': int(total_sleep),
        'rem_percentage': round(rem_percentage, 2),
        'deep_sleep_percentage': round(deep_percentage, 2),
        'light_sleep_percentage': round(light_percentage, 2),
        'awake_percentage': round(awake_percentage, 2),
        'sleep_latency': sleep_latency,
        'wake_after_sleep_onset': wake_after_sleep_onset,
        'sleep_score': round(sleep_score, 2),
    }


def _analyze_multiple_sessions(sessions: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Analyze multiple sleep sessions and return aggregate statistics."""
    if not sessions:
        return {
            'efficiency': 0.0,
            'total_sleep_duration': 0,
            'rem_percentage': 0.0,
            'deep_sleep_percentage': 0.0,
            'light_sleep_percentage': 0.0,
            'awake_percentage': 0.0,
        }
    
    # Analyze each session
    session_results = []
    for session in sessions:
        result = _analyze_single_session(session)
        session_results.append(result)
    
    # Create DataFrame for statistical analysis
    df = pd.DataFrame(session_results)
    
    # Calculate aggregate statistics
    return {
        'average_efficiency': round(df['efficiency'].mean(), 2),
        'average_sleep_duration': round(df['total_sleep_duration'].mean(), 1),
        'average_rem_percentage': round(df['rem_percentage'].mean(), 2),
        'average_deep_percentage': round(df['deep_sleep_percentage'].mean(), 2),
        'average_light_percentage': round(df['light_sleep_percentage'].mean(), 2),
        'average_awake_percentage': round(df['awake_percentage'].mean(), 2),
        'average_sleep_score': round(df['sleep_score'].mean(), 2),
        'total_sessions': len(sessions),
        'efficiency_std': round(df['efficiency'].std(), 2),
        'duration_std': round(df['total_sleep_duration'].std(), 1),
        'trend_efficiency': _calculate_trend(df['efficiency'].values),
        'trend_duration': _calculate_trend(df['total_sleep_duration'].values),
    }


def _calculate_sleep_score(
    efficiency: float,
    rem_percentage: float,
    deep_percentage: float,
    total_sleep: float,
    sleep_latency: int,
    wake_episodes: int
) -> float:
    """
    Calculate overall sleep quality score (0-100).
    
    Factors:
    - Efficiency (40% weight)
    - Stage distribution (30% weight)
    - Sleep duration (20% weight)
    - Sleep latency & wake episodes (10% weight)
    """
    # Efficiency score (0-40 points)
    efficiency_score = min(efficiency * 0.4, 40.0)
    
    # Stage distribution score (0-30 points)
    # Ideal: REM 20-25%, Deep 15-20%, Light 50-60%
    ideal_rem = 22.5
    ideal_deep = 17.5
    rem_score = max(0, 15 - abs(rem_percentage - ideal_rem))
    deep_score = max(0, 15 - abs(deep_percentage - ideal_deep))
    stage_score = rem_score + deep_score
    
    # Duration score (0-20 points)
    # Ideal: 7-9 hours (420-540 minutes)
    ideal_duration = 480  # 8 hours
    duration_diff = abs(total_sleep - ideal_duration)
    duration_score = max(0, 20 - (duration_diff / 60 * 20))
    
    # Latency & wake episodes score (0-10 points)
    latency_score = max(0, 5 - (sleep_latency / 30 * 5)) if sleep_latency <= 60 else 0
    wake_score = max(0, 5 - (wake_episodes * 1))
    quality_score = latency_score + wake_score
    
    total_score = efficiency_score + stage_score + duration_score + quality_score
    return min(100.0, max(0.0, total_score))


def _calculate_trend(values: np.ndarray) -> str:
    """
    Calculate trend direction using linear regression.
    
    Returns: 'improving', 'declining', or 'stable'
    """
    if len(values) < 3:
        return 'stable'
    
    x = np.arange(len(values))
    slope, intercept, r_value, p_value, std_err = stats.linregress(x, values)
    
    # Determine trend based on slope
    if abs(slope) < std_err:
        return 'stable'
    elif slope > 0:
        return 'improving'
    else:
        return 'declining'


def _parse_datetime(dt_string: Optional[str]) -> Optional[datetime]:
    """Parse ISO datetime string to datetime object."""
    if not dt_string:
        return None
    
    try:
        # Try ISO format
        return datetime.fromisoformat(dt_string.replace('Z', '+00:00'))
    except:
        try:
            # Try common formats
            for fmt in ['%Y-%m-%d %H:%M:%S', '%Y-%m-%dT%H:%M:%S']:
                try:
                    return datetime.strptime(dt_string, fmt)
                except:
                    continue
        except:
            pass
    
    return None


def analyze_sleep_trends(sessions: List[Dict[str, Any]], days: int = 30) -> Dict[str, Any]:
    """
    Analyze sleep trends over a specified time period.
    
    Args:
        sessions: List of sleep session data
        days: Number of days to analyze (default: 30)
    
    Returns:
        Dictionary with trend analysis including:
        - weekly_averages: Average metrics per week
        - correlations: Correlations between metrics
        - recommendations: Personalized recommendations
    """
    if not sessions:
        return {
            'weekly_averages': [],
            'correlations': {},
            'recommendations': [],
        }
    
    # Convert to DataFrame
    session_data = []
    for session in sessions:
        result = _analyze_single_session(session)
        result['date'] = _parse_datetime(session.get('start_time'))
        session_data.append(result)
    
    df = pd.DataFrame(session_data)
    
    if df.empty or 'date' not in df.columns:
        return {
            'weekly_averages': [],
            'correlations': {},
            'recommendations': [],
        }
    
    df = df.sort_values('date')
    df['week'] = df['date'].dt.isocalendar().week
    
    # Calculate weekly averages
    weekly_avg = df.groupby('week').agg({
        'efficiency': 'mean',
        'total_sleep_duration': 'mean',
        'rem_percentage': 'mean',
        'deep_sleep_percentage': 'mean',
        'sleep_score': 'mean',
    }).round(2)
    
    weekly_averages = weekly_avg.to_dict('index')
    
    # Calculate correlations
    numeric_cols = ['efficiency', 'total_sleep_duration', 'rem_percentage', 
                    'deep_sleep_percentage', 'sleep_score']
    correlations = df[numeric_cols].corr().to_dict()
    
    # Generate recommendations
    recommendations = _generate_recommendations(df)
    
    return {
        'weekly_averages': weekly_averages,
        'correlations': correlations,
        'recommendations': recommendations,
    }


def _generate_recommendations(df: pd.DataFrame) -> List[str]:
    """Generate personalized sleep recommendations based on data."""
    recommendations = []
    
    avg_efficiency = df['efficiency'].mean()
    avg_duration = df['total_sleep_duration'].mean()
    avg_rem = df['rem_percentage'].mean()
    avg_deep = df['deep_sleep_percentage'].mean()
    avg_score = df['sleep_score'].mean()
    
    if avg_efficiency < 85:
        recommendations.append("Your sleep efficiency is below optimal. Try going to bed and waking up at consistent times.")
    
    if avg_duration < 420:  # Less than 7 hours
        recommendations.append("You're getting less than 7 hours of sleep on average. Aim for 7-9 hours for optimal health.")
    elif avg_duration > 540:  # More than 9 hours
        recommendations.append("You're sleeping more than 9 hours on average. This might indicate underlying health issues.")
    
    if avg_rem < 15:
        recommendations.append("Your REM sleep is lower than recommended (15-25%). Consider reducing screen time before bed.")
    
    if avg_deep < 10:
        recommendations.append("Your deep sleep is lower than recommended (10-20%). Try maintaining a cooler bedroom temperature.")
    
    if avg_score < 70:
        recommendations.append("Your overall sleep quality could be improved. Focus on sleep hygiene practices.")
    
    if not recommendations:
        recommendations.append("Great job! Your sleep patterns look healthy. Keep maintaining your sleep schedule.")
    
    return recommendations


if __name__ == "__main__":
    # Example usage
    sample_data = {
        "stages": [
            {"type": "AWAKE", "duration": 15, "start_time": "2025-01-01T22:00:00Z", "end_time": "2025-01-01T22:15:00Z"},
            {"type": "LIGHT", "duration": 90, "start_time": "2025-01-01T22:15:00Z", "end_time": "2025-01-01T23:45:00Z"},
            {"type": "DEEP", "duration": 60, "start_time": "2025-01-01T23:45:00Z", "end_time": "2025-01-02T00:45:00Z"},
            {"type": "REM", "duration": 120, "start_time": "2025-01-02T00:45:00Z", "end_time": "2025-01-02T02:45:00Z"},
            {"type": "LIGHT", "duration": 180, "start_time": "2025-01-02T02:45:00Z", "end_time": "2025-01-02T05:45:00Z"},
            {"type": "DEEP", "duration": 45, "start_time": "2025-01-02T05:45:00Z", "end_time": "2025-01-02T06:30:00Z"},
        ],
        "start_time": "2025-01-01T22:00:00Z",
        "end_time": "2025-01-02T06:30:00Z",
    }
    
    result = analyze_sleep_data(sample_data)
    print(json.dumps(result, indent=2))
